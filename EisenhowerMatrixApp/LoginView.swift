import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import UIKit

struct LoginView: View {
    @State private var username: String = ""
    var onLogin: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Eisenhower Matrix")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Enter username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Login") {
                let trimmed = username.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                onLogin(trimmed)
            }
            .padding()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                if case .success(let authResults) = result,
                   let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                    onLogin(credential.user)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 45)
            .padding(.horizontal)

            GoogleSignInButton {
                guard let root = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                        .first?.rootViewController else { return }
                GIDSignIn.sharedInstance.signIn(withPresenting: root) { signInResult, error in
                    guard error == nil, let result = signInResult else { return }
                    let email = result.user.profile?.email ?? result.user.userID ?? ""
                    onLogin(email)
                }
            }
            .frame(height: 45)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    LoginView { _ in }
}
