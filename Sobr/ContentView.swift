//
//  ContentView.swift
//  Sobr
//

import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(DrinkStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router
        Group {
            if store.settings.onboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.smooth, value: store.settings.onboardingComplete)
        .sheet(
            isPresented: Binding(
                get: { router.openTodayLog && store.settings.onboardingComplete },
                set: { router.openTodayLog = $0 }
            )
        ) {
            LogDaySheet(date: Date())
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.rescheduleNotifications() }
            }
        }
    }
}

#Preview("Home") {
    ContentView()
        .environment(DrinkStore.makePreview())
        .environment(AppRouter.shared)
}

#Preview("Onboarding") {
    ContentView()
        .environment(DrinkStore(inMemory: true))
        .environment(AppRouter.shared)
}
