import Foundation

enum ScriptureSource: String, Codable, CaseIterable, Identifiable {
    case mahabharata
    case ramayanam
    case hanuman_chalisa
    case sai_baba
    case quran
    case bible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mahabharata: return "Mahabharata"
        case .ramayanam: return "Ramayanam"
        case .hanuman_chalisa: return "Hanuman Chalisa"
        case .sai_baba: return "Sai Baba Charitra"
        case .quran: return "Quran"
        case .bible: return "Bible"
        }
    }
}

struct Scripture: Codable, Identifiable {
    var id: String
    var source: ScriptureSource
    var verseRef: String
    var language: String // en, hi, te, ur
    var text: String
    var explanation: String?
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case source
        case verseRef = "verse_ref"
        case language
        case text
        case explanation
        case tags
    }
}

