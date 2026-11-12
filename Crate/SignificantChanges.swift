import PermissionKit
import StoreKit

@available(iOS 26.2, *)
@MainActor
final class VersionManager {
    private(set) var handledCount = 0
    func handleAllChanges() { handledCount += 1 }
}

@available(iOS 26.2, *)
func significantUpdateQuestion() -> PermissionQuestion<SignificantAppUpdateTopic> {
    let topic = SignificantAppUpdateTopic(
        description: "This update adds direct messages between collectors and sellers."
    )
    let question = PermissionQuestion(significantAppUpdateTopic: topic)
    return question
}

@available(iOS 26.2, *)
@MainActor
func listenForApprovals(versionManager: VersionManager) async {
    for await response in AskCenter.shared.responses(for: SignificantAppUpdateTopic.self) {
        guard response.choice.answer == .approval else { continue }
        versionManager.handleAllChanges()
    }
}

@available(iOS 26.2, *)
func currentAgeRatingCode() async -> Int? {
    await AppStore.ageRatingCode
}
