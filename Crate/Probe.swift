@preconcurrency import DeclaredAgeRange
import SwiftUI

struct ProbeModifier: ViewModifier {
    @Environment(\.requestAgeRange) private var requestAgeRange

    func body(content: Content) -> some View {
        content.task {
            guard ProcessInfo.processInfo.arguments.contains("-probe") else { return }
            if #available(iOS 26.4, *) {
                do { print("PROBE requiredRegulatoryFeatures:", try await AgeRangeService.shared.requiredRegulatoryFeatures) }
                catch { print("PROBE requiredRegulatoryFeatures threw:", String(reflecting: error)) }
            }
            if #available(iOS 26.2, *) {
                do { print("PROBE isEligibleForAgeFeatures:", try await AgeRangeService.shared.isEligibleForAgeFeatures) }
                catch { print("PROBE isEligibleForAgeFeatures threw:", String(reflecting: error)) }
            }
            try? await Task.sleep(for: .seconds(3))
            do { print("PROBE requestAgeRange:", String(reflecting: try await requestAgeRange(ageGates: 13, 16, 18))) }
            catch { print("PROBE requestAgeRange threw:", String(reflecting: error)) }
        }
    }
}
