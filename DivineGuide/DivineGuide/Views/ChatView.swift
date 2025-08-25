import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    @StateObject private var speech = SpeechService.shared
    @EnvironmentObject var auth: AuthViewModel
    let source: ScriptureSource
    let language: LanguageCode

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            HStack {
                                if msg.role == .assistant { Spacer(minLength: 0) }
                                TextBubble(text: msg.text, isUser: msg.role == .user)
                                if msg.role == .user { Spacer(minLength: 0) }
                            }
                            .id(msg.id)
                        }
                    }.padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            HStack(spacing: 8) {
                TextField("Type your thoughts...", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                Button(action: { toggleRecord() }) {
                    Image(systemName: speech.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                }
                Button {
                    Task { await vm.send() }
                } label: {
                    Image(systemName: "paperplane.fill").font(.system(size: 24))
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isProcessing)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(source.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.setContext(source: source, language: language)
            Task {
                await speech.requestPermissions()
                await vm.prefetchSource()
            }
        }
        .onChange(of: vm.messages.last?.text) { text in
            guard let text = text, vm.messages.last?.role == .assistant else { return }
            SpeechService.shared.speak(text, language: language.rawValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isCurrentFavorite ? "star.fill" : "star")
                }
                .disabled(vm.lastScripture == nil || auth.userProfile == nil)
            }
        }
    }

    private func toggleRecord() {
        if speech.isRecording {
            speech.stopRecording()
        } else {
            let localeId: String
            switch language {
            case .en: localeId = "en-US"
            case .hi: localeId = "hi-IN"
            case .te: localeId = "te-IN"
            case .ur: localeId = "ur-PK"
            }
            try? speech.startRecording(locale: Locale(identifier: localeId)) { transcript in
                vm.inputText = transcript
            }
        }
    }
}

extension ChatView {
    var isCurrentFavorite: Bool {
        guard let s = vm.lastScripture, let profile = auth.userProfile else { return false }
        return profile.favoriteIds.contains(s.id)
    }

    func toggleFavorite() {
        guard let s = vm.lastScripture, var profile = auth.userProfile else { return }
        Task {
            do {
                if isCurrentFavorite {
                    try await FirebaseService.shared.removeFavorite(userId: profile.id, scriptureId: s.id)
                    profile.favoriteIds.removeAll(where: { $0 == s.id })
                } else {
                    try await FirebaseService.shared.addFavorite(userId: profile.id, scriptureId: s.id)
                    profile.favoriteIds.append(s.id)
                }
                auth.userProfile = profile
            } catch { }
        }
    }
}

private struct TextBubble: View {
    let text: String
    let isUser: Bool

    var body: some View {
        Text(text)
            .padding(12)
            .background(isUser ? Color.blue.opacity(0.1) : Color.green.opacity(0.15))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
    }
}

