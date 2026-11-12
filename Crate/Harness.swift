import SwiftUI

struct CollectionView: View {
    @Environment(AgeGate.self) private var ageGate

    var body: some View {
        NavigationStack {
            List {
                Section("Policy") {
                    LabeledContent("State", value: String(describing: ageGate.policy))
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
