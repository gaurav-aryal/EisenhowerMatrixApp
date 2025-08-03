//
//  EisenhowerMatrixApp_iOSApp.swift
//  EisenhowerMatrixApp_iOS
//
//  Created by user280681 on 8/3/25.
//

import SwiftUI

@main
struct EisenhowerMatrixApp_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(taskManager: TaskManager(userId: "default"))
        }
    }
}
