//
//  EisenhowerMatrixAppApp.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//

import SwiftUI

@main
struct EisenhowerMatrixAppApp: App {
    @State private var currentUser: String?

    var body: some Scene {
        WindowGroup {
            if let user = currentUser {
                ContentView(taskManager: TaskManager(userId: user))
            } else {
                LoginView { username in
                    currentUser = username
                }
            }
        }
    }
}
