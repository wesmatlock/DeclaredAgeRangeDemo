import SwiftUI

struct CollectionView: View {
    @Environment(AgeGate.self) private var ageGate

    var body: some View {
        NavigationStack {
            List {
                Section("Policy") {
                    LabeledContent("State", value: ageGate.policy.statusText)
                    LabeledContent("Must ask at launch", value: ageGate.mustAsk ? "yes" : "no")
                    LabeledContent("Asking", value: ageGate.isAsking ? "yes" : "no")
                }
                Section("Features") {
                    ForEach(GatedFeature.allForHarness, id: \.self) { feature in
                        LabeledContent(String(describing: feature), value: ageGate.policy.allows(feature) ? "allowed" : "locked")
                    }
                }
                Section {
                    Button("Clear Stored Policy", role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "agePolicy.v1")
                    }
                } footer: {
                    Text("Relaunch the app after clearing.")
                }
            }
            .navigationTitle("Collection")
            .modifier(ProbeModifier())
        }
    }
}

struct MarketplaceView: View {
    var body: some View {
        ContentUnavailableView("Marketplace", systemImage: "tag", description: Text("Unlocked."))
    }
}

extension GatedFeature: Hashable {
    static let allForHarness: [GatedFeature] = [.collection, .communityNotes, .sellerMessages, .marketplace]
}

extension AgePolicy {
    var statusText: String {
        switch self {
        case .notAsked: "Not asked"
        case .declined: "Declined"
        case .unavailable: "Unavailable"
        case let .known(signal):
            [signal.tier.statusText, signal.source.statusText, signal.communicationLimited ? "communication limits" : nil]
                .compactMap { $0 }
                .joined(separator: " · ")
        }
    }
}

extension AgeTier {
    var statusText: String {
        switch self {
        case .under13: "Under 13"
        case .from13To15: "13–15"
        case .from16To17: "16–17"
        case .adult: "18+"
        }
    }
}

extension DeclarationSource {
    var statusText: String {
        switch self {
        case .selfDeclared: "self-declared"
        case .guardianDeclared: "guardian-declared"
        case .confirmed: "confirmed"
        case .unknown: "unknown source"
        }
    }
}
