import Foundation

enum LanguageCode: String, CaseIterable {
    case en, hi, te, ur
}

struct AIResponse: Codable {
    let detectedLanguage: LanguageCode
    let moodTags: [String]
    let targetLanguage: LanguageCode
    let answer: String
}

final class AIService {
    static let shared = AIService()

    private let session: URLSession = .shared
    private let baseURL = URL(string: "https://api-inference.huggingface.co/models")!

    private var apiToken: String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else { return nil }
        return dict["HUGGINGFACE_API_TOKEN"] as? String
    }

    // Simple heuristics for mood detection as fallback
    private func heuristicMoodTags(for text: String) -> [String] {
        let lower = text.lowercased()
        var tags: [String] = []
        if ["sad", "unhappy", "depressed", "down", "cry"].contains(where: lower.contains) { tags.append("sad") }
        if ["happy", "joy", "grateful", "thankful"].contains(where: lower.contains) { tags.append("happy") }
        if ["angry", "mad", "frustrated"].contains(where: lower.contains) { tags.append("anger") }
        if ["fear", "anxious", "worry", "stress"].contains(where: lower.contains) { tags.append("anxiety") }
        if tags.isEmpty { tags = ["general"] }
        return tags
    }

    func detectLanguageAndMood(text: String, preferred: LanguageCode) async -> (LanguageCode, [String]) {
        // Minimal offline detection using character ranges and keywords
        let lower = text.lowercased()
        if lower.range(of: #"[\u0C00-\u0C7F]"#, options: .regularExpression) != nil { return (.te, heuristicMoodTags(for: text)) }
        if lower.range(of: #"[\u0900-\u097F]"#, options: .regularExpression) != nil { return (.hi, heuristicMoodTags(for: text)) }
        if lower.range(of: #"[\u0600-\u06FF]"#, options: .regularExpression) != nil { return (.ur, heuristicMoodTags(for: text)) }
        if lower.range(of: #"[a-z]"#, options: .regularExpression) != nil { return (.en, heuristicMoodTags(for: text)) }
        return (preferred, heuristicMoodTags(for: text))
    }

    func translate(_ text: String, to target: LanguageCode) async -> String {
        guard let token = apiToken else { return text }
        // Use Helsinki-NLP/opus-mt for free tier translation
        let modelMap: [LanguageCode: String] = [
            .en: "Helsinki-NLP/opus-mt-mul-en",
            .hi: "Helsinki-NLP/opus-mt-mul-hi",
            .te: "Helsinki-NLP/opus-mt-mul-te",
            .ur: "Helsinki-NLP/opus-mt-mul-ur"
        ]
        guard let model = modelMap[target] else { return text }
        var request = URLRequest(url: baseURL.appendingPathComponent(model))
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["inputs": text])
        do {
            let (data, _) = try await session.data(for: request)
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = arr.first,
               let translationText = first["translation_text"] as? String {
                return translationText
            }
        } catch { }
        return text
    }

    func composeAnswer(for scripture: Scripture, userLanguage: LanguageCode) async -> String {
        let base = "\(scripture.verseRef)\n\n\(scripture.text)\n\nLife lesson: \(scripture.explanation ?? "Reflect on this verse kindly.")"
        if userLanguage == .en || scripture.language == userLanguage.rawValue { return base }
        return await translate(base, to: userLanguage)
    }
}

