import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var userProfile: UserProfile?

    init() {
        FirebaseService.shared.auth.addStateDidChangeListener { _, user in
            Task {
                if let user = user {
                    self.isAuthenticated = true
                    self.userProfile = try? await FirebaseService.shared.fetchUserProfile(userId: user.uid)
                } else {
                    self.isAuthenticated = false
                    self.userProfile = nil
                }
            }
        }
    }

    func signIn() async {
        errorMessage = nil
        do {
            try await FirebaseService.shared.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp() async {
        errorMessage = nil
        do {
            try await FirebaseService.shared.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset() async {
        errorMessage = nil
        do {
            try await FirebaseService.shared.sendPasswordReset(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do { try FirebaseService.shared.signOut() } catch { errorMessage = error.localizedDescription }
    }
}