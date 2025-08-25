import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

final class FirebaseService {
    static let shared = FirebaseService()

    let auth: Auth
    let db: Firestore

    private init() {
        self.auth = Auth.auth()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
        self.db = Firestore.firestore()
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        _ = try await auth.signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await auth.createUser(withEmail: email, password: password)
    }

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - User profile

    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let doc = try await db.collection("users").document(userId).getDocument()
        if let data = doc.data() {
            return try Firestore.Decoder().decode(UserProfile.self, from: data)
        }
        let profile = UserProfile(id: userId, email: auth.currentUser?.email ?? "", preferredLanguage: "en")
        try db.collection("users").document(userId).setData(from: profile)
        return profile
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        try db.collection("users").document(profile.id).setData(from: profile, merge: true)
    }

    // MARK: - Scriptures

    func fetchScriptures(source: ScriptureSource, limit: Int = 50) async throws -> [Scripture] {
        let snapshot = try await db.collection("scriptures")
            .whereField("source", isEqualTo: source.rawValue)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.compactMap { doc in
            var scripture = try doc.data(as: Scripture.self)
            scripture.id = doc.documentID
            return scripture
        }
    }

    func searchScriptures(source: ScriptureSource, tags: [String], limit: Int = 20) async throws -> [Scripture] {
        // Simple client-side filter for tags after basic source query (free tier compatible)
        let all = try await fetchScriptures(source: source, limit: 200)
        if tags.isEmpty { return all }
        let lower = Set(tags.map { $0.lowercased() })
        return all.filter { !$0.tags.isEmpty && !$0.tags.map({ $0.lowercased() }).filter(lower.contains).isEmpty }
            .prefix(limit)
            .map { $0 }
    }

    func fetchScripture(by id: String) async throws -> Scripture? {
        let doc = try await db.collection("scriptures").document(id).getDocument()
        guard let data = doc.data() else { return nil }
        var s = try Firestore.Decoder().decode(Scripture.self, from: data)
        s.id = doc.documentID
        return s
    }

    // MARK: - Favorites
    func addFavorite(userId: String, scriptureId: String) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.updateData(["favoriteIds": FieldValue.arrayUnion([scriptureId])])
    }

    func removeFavorite(userId: String, scriptureId: String) async throws {
        let ref = db.collection("users").document(userId)
        try await ref.updateData(["favoriteIds": FieldValue.arrayRemove([scriptureId])])
    }

    func fetchFavorites(userId: String) async throws -> [Scripture] {
        let user = try await db.collection("users").document(userId).getDocument()
        let favs = (user.data()? ["favoriteIds"] as? [String]) ?? []
        var results: [Scripture] = []
        for id in favs {
            if let s = try await fetchScripture(by: id) {
                results.append(s)
            }
        }
        return results
    }
}

