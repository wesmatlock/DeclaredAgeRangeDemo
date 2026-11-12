@preconcurrency import DeclaredAgeRange
import Foundation
import Observation

@MainActor
@Observable
final class AgeGate {
    private(set) var policy: AgePolicy
    private(set) var mustAsk = false
    private(set) var isAsking = false

    private let defaults: UserDefaults
    private static let storageKey = "agePolicy.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        policy = Self.loadPolicy(from: defaults) ?? .notAsked
    }

    func refreshRequirements() async {
        if #available(iOS 26.4, macOS 26.4, *) {
            let features = (try? await AgeRangeService.shared.requiredRegulatoryFeatures) ?? []
            mustAsk = features.contains(.declaredAgeRangeRequired)
        } else if #available(iOS 26.2, macOS 26.2, *) {
            mustAsk = (try? await AgeRangeService.shared.isEligibleForAgeFeatures) ?? false
        } else {
            mustAsk = false
        }
    }

    func resolve(_ ask: () async throws -> AgeRangeService.Response) async {
        guard !isAsking else { return }
        isAsking = true
        defer { isAsking = false }

        do {
            commit(AgePolicy(try await ask()))
        } catch let error as AgeRangeService.Error {
            switch error {
            case .declinedOnboarding:
                commit(.declined)
            case .network:
                break
            case .invalidRequest:
                assertionFailure("Each age range must span at least two years")
                markUnavailable()
            case .notAvailable, .invalidAccount:
                markUnavailable()
            @unknown default:
                markUnavailable()
            }
        } catch {
            markUnavailable()
        }
    }

    private func markUnavailable() {
        if case .known = policy { return }
        policy = .unavailable
    }

    private func commit(_ newPolicy: AgePolicy) {
        policy = newPolicy
        guard let data = try? JSONEncoder().encode(newPolicy) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private static func loadPolicy(from defaults: UserDefaults) -> AgePolicy? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AgePolicy.self, from: data)
    }
}
