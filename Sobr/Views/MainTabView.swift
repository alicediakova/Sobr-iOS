import SwiftUI

@MainActor
struct MainTabView: View {
    var body: some View {
        TabView {
            CalendarTabView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color.sobrAccent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
