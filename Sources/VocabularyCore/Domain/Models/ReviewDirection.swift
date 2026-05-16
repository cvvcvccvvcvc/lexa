import Foundation

public enum ReviewDirection: String, Codable, CaseIterable, Sendable {
    case enToRu
    case ruToEn

    public var opposite: ReviewDirection {
        switch self {
        case .enToRu:
            .ruToEn
        case .ruToEn:
            .enToRu
        }
    }
}

public enum ReviewAnswer: Sendable {
    case correct
    case wrong
}
