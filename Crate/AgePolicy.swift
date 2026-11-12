import DeclaredAgeRange

enum AgeTier: Int, Codable, Comparable, Sendable {
    case under13
    case from13To15
    case from16To17
    case adult

    init(lowerBound: Int?) {
        guard let lowerBound else {
            self = .under13
            return
        }
        switch lowerBound {
        case 18...: self = .adult
        case 16...: self = .from16To17
        case 13...: self = .from13To15
        default: self = .under13
        }
    }

    static func < (lhs: AgeTier, rhs: AgeTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum DeclarationSource: String, Codable, Sendable {
    case selfDeclared
    case guardianDeclared
    case confirmed
    case unknown
}

struct AgeSignal: Codable, Equatable, Sendable {
    var tier: AgeTier
    var source: DeclarationSource
    var communicationLimited: Bool
}

enum AgePolicy: Codable, Equatable, Sendable {
    case notAsked
    case declined
    case unavailable
    case known(AgeSignal)
}
extension AgePolicy {
    init(_ response: AgeRangeService.Response) {
        switch response {
        case .declinedSharing:
            self = .declined
        case let .sharing(range):
            self = .known(AgeSignal(
                tier: AgeTier(lowerBound: range.lowerBound),
                source: DeclarationSource(range.ageRangeDeclaration),
                communicationLimited: range.activeParentalControls.contains(.communicationLimits)
            ))
        @unknown default:
            self = .unavailable
        }
    }
}

extension DeclarationSource {
    init(_ declaration: AgeRangeService.AgeRangeDeclaration?) {
        guard let declaration else {
            self = .unknown
            return
        }
        if #available(iOS 26.5, macOS 26.5, *) {
            if case .confirmed = declaration {
                self = .confirmed
                return
            }
        }
        switch declaration {
        case .selfDeclared: self = .selfDeclared
        case .guardianDeclared: self = .guardianDeclared
        default: self = .unknown
        }
    }
}
enum GatedFeature: Sendable {
    case collection
    case communityNotes
    case sellerMessages
    case marketplace

    var minimumTier: AgeTier? {
        switch self {
        case .collection: nil
        case .communityNotes: .from13To15
        case .sellerMessages: .from16To17
        case .marketplace: .adult
        }
    }
}

extension AgePolicy {
    func allows(_ feature: GatedFeature) -> Bool {
        guard let minimum = feature.minimumTier else { return true }
        guard case let .known(signal) = self else { return false }
        if feature == .sellerMessages, signal.communicationLimited { return false }
        return signal.tier >= minimum
    }

    var canAsk: Bool {
        switch self {
        case .notAsked, .declined: true
        case .unavailable, .known: false
        }
    }
}
