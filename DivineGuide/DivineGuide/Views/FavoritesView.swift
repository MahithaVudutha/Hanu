import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var favorites: [Scripture] = []

    var body: some View {
        List(favorites) { s in
            VStack(alignment: .leading, spacing: 4) {
                Text(s.verseRef).font(.headline)
                Text(s.text).font(.subheadline)
            }
        }
        .navigationTitle("My Favorites")
        .onAppear { Task { await loadFavorites() } }
    }

    private func loadFavorites() async {
        guard let userId = auth.userProfile?.id else { return }
        favorites = (try? await FirebaseService.shared.fetchFavorites(userId: userId)) ?? []
    }
}

