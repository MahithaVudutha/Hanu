import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedSource: ScriptureSource?
    @State private var language: LanguageCode = .en

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color("PastelGold"), .white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack {
                        Text("Divine Guide").font(.title).bold()
                        Spacer()
                        Menu {
                            Picker("Language", selection: $language) {
                                Text("English").tag(LanguageCode.en)
                                Text("हिंदी").tag(LanguageCode.hi)
                                Text("తెలుగు").tag(LanguageCode.te)
                                Text("اردو").tag(LanguageCode.ur)
                            }
                        } label: {
                            Image(systemName: "globe")
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        NavigationLink(destination: FavoritesView().environmentObject(auth)) {
                            Image(systemName: "star.fill")
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        Button(action: { auth.signOut() }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }.padding(.horizontal)

                    GridView(language: $language)

                    NavigationLink(isActive: Binding(get: { selectedSource != nil }, set: { if !$0 { selectedSource = nil } })) {
                        if let source = selectedSource {
                            ChatView(source: source, language: language).environmentObject(auth)
                        } else { EmptyView() }
                    } label: { EmptyView() }
                }
            }
        }
    }

    @ViewBuilder
    private func GridView(language: Binding<LanguageCode>) -> some View {
        let sources = ScriptureSource.allCases
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(sources) { source in
                Button {
                    selectedSource = source
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: iconName(for: source))
                            .resizable().scaledToFit().frame(height: 60)
                            .foregroundColor(.orange)
                        Text(source.displayName).bold().foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 3)
                }
            }
        }.padding()
    }

    private func iconName(for source: ScriptureSource) -> String {
        switch source {
        case .mahabharata: return "hare"
        case .ramayanam: return "sun.max"
        case .hanuman_chalisa: return "bolt.heart"
        case .sai_baba: return "figure.walk"
        case .quran: return "book"
        case .bible: return "cross.vial"
        }
    }
}

