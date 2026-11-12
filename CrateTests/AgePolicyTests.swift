import Testing
@testable import Crate

struct AgePolicyTests {
    @Test(arguments: zip(
        [nil, 12, 13, 14, 15, 16, 17, 18, 40] as [Int?],
        [AgeTier.under13, .under13, .from13To15, .from13To15, .from13To15,
         .from16To17, .from16To17, .adult, .adult]
    ))
    func tierComesFromLowerBound(lowerBound: Int?, expected: AgeTier) {
        #expect(AgeTier(lowerBound: lowerBound) == expected)
    }

    @Test func declinedGetsOnlyTheCollection() {
        let policy = AgePolicy.declined
        #expect(policy.allows(.collection))
        #expect(!policy.allows(.communityNotes))
        #expect(!policy.allows(.marketplace))
    }

    @Test func communicationLimitsBlockSellerMessages() {
        let policy = AgePolicy.known(AgeSignal(
            tier: .from16To17,
            source: .guardianDeclared,
            communicationLimited: true
        ))
        #expect(policy.allows(.communityNotes))
        #expect(!policy.allows(.sellerMessages))
    }
}
