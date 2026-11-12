@preconcurrency import DeclaredAgeRange
import SwiftUI

@MainActor
extension DeclaredAgeRangeAction {
    func requestTiers() async throws -> AgeRangeService.Response {
        try await self(ageGates: 13, 16, 18)
    }
}

@main
struct CrateApp: App {
    @State private var ageGate = AgeGate()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(ageGate)
        }
    }
}

struct RootView: View {
    @Environment(AgeGate.self) private var ageGate
    @Environment(\.requestAgeRange) private var requestAgeRange

    var body: some View {
        TabView {
            Tab("Collection", systemImage: "square.stack") {
                CollectionView()
            }
            Tab("Market", systemImage: "tag") {
                AgeGated(.marketplace) {
                    MarketplaceView()
                }
            }
        }
        .task {
            await ageGate.refreshRequirements()
            guard ageGate.mustAsk else { return }
            await ageGate.resolve { try await requestAgeRange.requestTiers() }
        }
    }
}
struct AgeGated<Content: View>: View {
    private let feature: GatedFeature
    private let content: Content

    @Environment(AgeGate.self) private var ageGate
    @Environment(\.requestAgeRange) private var requestAgeRange

    init(_ feature: GatedFeature, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.content = content()
    }

    var body: some View {
        if ageGate.policy.allows(feature) {
            content
        } else {
            ContentUnavailableView {
                Label("Not Available", systemImage: "lock")
            } description: {
                Text(message)
            } actions: {
                if ageGate.policy.canAsk {
                    Button("Share Age Range") {
                        Task {
                            await ageGate.resolve { try await requestAgeRange.requestTiers() }
                        }
                    }
                    .disabled(ageGate.isAsking)
                }
            }
        }
    }

    private var message: String {
        switch ageGate.policy {
        case .notAsked:
            "Share your age range to use this. The app gets a range, never your birthday."
        case .declined:
            "You chose not to share your age range. You can share it whenever you like."
        case .unavailable:
            "Age range sharing isn't available for this account right now."
        case .known:
            "This part of the app isn't available for your age range."
        }
    }
}
