import Foundation
import Combine

#if canImport(HealthKit)
import HealthKit
#endif

struct HealthKitDailySummary {
    let stepsToday: Int
    let sleepHoursLastNight: Double
    let activeCaloriesToday: Double
}

enum HealthKitAuthorizationState {
    case notRequested
    case requesting
    case denied
    case authorized
    case unavailable
}

protocol HealthKitManaging {
    var authorizationState: HealthKitAuthorizationState { get }
    func refreshAuthorizationState()
    func requestAuthorization() async
    func fetchDailySummary() async throws -> HealthKitDailySummary
}

@MainActor
final class HealthKitManager: ObservableObject, HealthKitManaging {
    @Published private(set) var authorizationState: HealthKitAuthorizationState = .notRequested

    private enum StorageKeys {
        static let hasRequestedAuthorization = "healthkit.hasRequestedAuthorization"
        static let didDenyAuthorization = "healthkit.didDenyAuthorization"
    }

    private let defaults: UserDefaults

    #if canImport(HealthKit)
    private let healthStore = HKHealthStore()
    private let requestedReadTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let activeCalories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeCalories)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()
    #endif

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refreshAuthorizationState()
    }

    func refreshAuthorizationState() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .unavailable
            return
        }

        guard !requestedReadTypes.isEmpty else {
            authorizationState = .unavailable
            return
        }

        if !defaults.bool(forKey: StorageKeys.hasRequestedAuthorization) {
            authorizationState = .notRequested
            return
        }

        authorizationState = defaults.bool(forKey: StorageKeys.didDenyAuthorization) ? .denied : .authorized
        #else
        authorizationState = .unavailable
        #endif
    }

    func requestAuthorization() async {
        authorizationState = .requesting

        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .unavailable
            return
        }

        do {
            try await requestHealthKitAuthorization()
            defaults.set(true, forKey: StorageKeys.hasRequestedAuthorization)
            defaults.set(false, forKey: StorageKeys.didDenyAuthorization)
            refreshAuthorizationState()
        } catch {
            defaults.set(true, forKey: StorageKeys.hasRequestedAuthorization)
            defaults.set(true, forKey: StorageKeys.didDenyAuthorization)
            authorizationState = .denied
        }
        #else
        authorizationState = .unavailable
        #endif
    }

    func fetchDailySummary() async throws -> HealthKitDailySummary {
        #if canImport(HealthKit)
        guard authorizationState != .notRequested, authorizationState != .denied else {
            throw HealthKitError.notAuthorized
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay

        async let steps = sumQuantity(
            identifier: .stepCount,
            unit: HKUnit.count(),
            from: startOfDay,
            to: now
        )

        async let calories = sumQuantity(
            identifier: .activeEnergyBurned,
            unit: HKUnit.kilocalorie(),
            from: startOfDay,
            to: now
        )

        async let sleepHours = sleepHours(from: yesterday, to: now)

        return try await HealthKitDailySummary(
            stepsToday: Int(steps.rounded()),
            sleepHoursLastNight: sleepHours,
            activeCaloriesToday: calories
        )
        #else
        throw HealthKitError.unavailable
        #endif
    }
}

#if canImport(HealthKit)
private extension HealthKitManager {
    enum HealthKitError: Error {
        case unavailable
        case notAuthorized
        case invalidType
        case queryFailure
    }

    func requestHealthKitAuthorization() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: requestedReadTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthKitError.queryFailure)
                }
            }
        }
    }

    func sumQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit, from startDate: Date, to endDate: Date) async throws -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.invalidType
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    func sleepHours(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.invalidType
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let categorySamples = (samples as? [HKCategorySample]) ?? []
                let totalSeconds = categorySamples.reduce(0.0) { partial, sample in
                    guard Self.isAsleep(sample.value) else { return partial }
                    return partial + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            healthStore.execute(query)
        }
    }

    nonisolated static func isAsleep(_ value: Int) -> Bool {
        if #available(iOS 16.0, *) {
            return value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
        }

        // Pre iOS 16 legacy value for "asleep".
        return value == 1
    }
}
#endif
