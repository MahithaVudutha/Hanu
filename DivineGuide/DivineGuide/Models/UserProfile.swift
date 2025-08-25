import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    var email: String
    var displayName: String?
    var preferredLanguage: String // en, hi, te, ur
    var favoriteIds: [String]

    init(id: String, email: String, displayName: String? = nil, preferredLanguage: String = "en", favoriteIds: [String] = []) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.preferredLanguage = preferredLanguage
        self.favoriteIds = favoriteIds
    }
}

