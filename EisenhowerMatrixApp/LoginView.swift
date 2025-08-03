import SwiftUI

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
        }
        .padding()
    }
}

#Preview {
    LoginView { _ in }
}
