import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isSignUp = false
    @State private var isForgot = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color("PastelGold"), Color("PastelBlue")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                Text("Divine Guide")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                Text("Spiritual guidance for all ages")
                    .foregroundColor(.white.opacity(0.9))

                VStack(spacing: 12) {
                    TextField("Email", text: $auth.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    SecureField("Password", text: $auth.password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)

                    if let err = auth.errorMessage { Text(err).foregroundColor(.red).font(.footnote) }

                    Button {
                        Task { await auth.signIn() }
                    } label: {
                        Text("Sign In").bold()
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                    HStack {
                        Button("Create Account") { isSignUp = true }
                        Spacer()
                        Button("Forgot Password") { isForgot = true }
                    }.foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(16)
                .padding()

                Spacer()
            }
        }
        .sheet(isPresented: $isSignUp) { SignUpView().environmentObject(auth) }
        .sheet(isPresented: $isForgot) { ForgotPasswordView().environmentObject(auth) }
    }
}

struct SignUpView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            Form {
                TextField("Email", text: $auth.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                SecureField("Password", text: $auth.password)
                if let err = auth.errorMessage { Text(err).foregroundColor(.red) }
                Button("Create Account") { Task { await auth.signUp(); if auth.isAuthenticated { dismiss() } } }
            }.navigationTitle("Create Account")
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            Form {
                TextField("Email", text: $auth.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if let err = auth.errorMessage { Text(err).foregroundColor(.red) }
                Button("Send Reset Link") { Task { await auth.sendPasswordReset(); dismiss() } }
            }.navigationTitle("Forgot Password")
        }
    }
}