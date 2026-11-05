//
//  SobrApp.swift
//  Sobr
//

import SwiftUI

@main
struct SobrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = DrinkStore()
    @State private var router = AppRouter.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(router)
                .tint(Color.sobrAccent)
        }
    }
}
