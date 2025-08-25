import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant }
    let id: String
    let role: Role
    let text: String
    let timestamp: Date
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false

    var currentSource: ScriptureSource = .mahabharata
    var language: LanguageCode = .en
    @Published var lastScripture: Scripture?

    func setContext(source: ScriptureSource, language: LanguageCode) {
        self.currentSource = source
        self.language = language
    }

    func prefetchSource() async {
        if let fetched = try? await FirebaseService.shared.fetchScriptures(source: currentSource, limit: 200) {
            LocalCacheService.shared.saveScriptures(fetched, for: currentSource)
        }
    }

    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMsg = ChatMessage(id: UUID().uuidString, role: .user, text: trimmed, timestamp: Date())
        messages.append(userMsg)
        inputText = ""
        await process(text: userMsg.text)
    }

    private func process(text: String) async {
        isProcessing = true
        defer { isProcessing = false }

        let (detectedLang, moodTags) = await AIService.shared.detectLanguageAndMood(text: text, preferred: language)
        let scriptures = (try? await FirebaseService.shared.searchScriptures(source: currentSource, tags: moodTags, limit: 1)) ?? []
        var selected = scriptures.first
        if selected == nil {
            // Fallback to local cache
            let cached = LocalCacheService.shared.loadScriptures(for: currentSource)
            let lower = Set(moodTags.map { $0.lowercased() })
            selected = cached.first(where: { !$0.tags.map { $0.lowercased() }.filter(lower.contains).isEmpty }) ?? cached.first
        }
        let responseText: String
        if let scripture = selected {
            self.lastScripture = scripture
            responseText = await AIService.shared.composeAnswer(for: scripture, userLanguage: language)
        } else {
            // Fallback simple empathy response
            let base = "I understand. Let's reflect with kindness and courage."
            responseText = await AIService.shared.translate(base, to: language)
        }
        let assistantMsg = ChatMessage(id: UUID().uuidString, role: .assistant, text: responseText, timestamp: Date())
        messages.append(assistantMsg)
    }
}

