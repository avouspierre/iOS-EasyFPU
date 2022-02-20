import Foundation

struct CarbsEntryNS: JSON, Equatable, Hashable {
    let createdAt: Date
    let carbs: Decimal
    let enteredBy: String?

    static let manual = "easy FPU"

    static func == (lhs: CarbsEntryNS, rhs: CarbsEntryNS) -> Bool {
        lhs.createdAt == rhs.createdAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
    }
}

extension CarbsEntryNS {
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case carbs
        case enteredBy
    }
}
