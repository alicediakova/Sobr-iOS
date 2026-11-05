import SwiftUI

@MainActor
struct SettingsTabView: View {
    @Environment(DrinkStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: SettingsViewModel?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(
                        "Daily Reminder",
                        isOn: Binding(
                            get: { store.settings.reminderEnabled },
                            set: { enabled in
                                Task { await model?.setReminderEnabled(enabled) }
                            }
                        )
                    )
                    .tint(Color.sobrAccent)
                    .listRowBackground(Color.sobrCard)

                    if store.settings.reminderEnabled {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { model?.reminderTime ?? DateKey.date(fromTime: store.settings.reminderTime) },
                                set: { model?.updateTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .listRowBackground(Color.sobrCard)
                    }

                    if model?.showDeniedNote == true {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are off for Sobr. Turn them on in Settings to get the evening reminder.")
                                .font(.footnote)
                                .foregroundStyle(Color.sobrSecondary)
                            Button("Open Settings") {
                                model?.openSettings()
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.sobrAccent)
                        }
                        .listRowBackground(Color.sobrCard)
                    }
                } header: {
                    Text("Reminder")
                }

                Section("Calendar") {
                    Picker(
                        "Week Starts On",
                        selection: Binding(
                            get: { store.settings.weekStartsOn },
                            set: { store.setWeekStartsOn($0) }
                        )
                    ) {
                        Text("Monday").tag(1)
                        Text("Sunday").tag(0)
                    }
                    .listRowBackground(Color.sobrCard)
                }

                Section("Data") {
                    Button("Delete All Data", role: .destructive) {
                        confirmDelete = true
                    }
                    .listRowBackground(Color.sobrCard)
                }

                Section {
                    Text("Sobr has no account and no servers. Everything stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(Color.sobrSecondary)
                        .listRowBackground(Color.sobrCard)

                    Link("Send Feedback", destination: URL(string: "mailto:?subject=Sobr%20Feedback")!)
                        .foregroundStyle(Color.sobrAccent)
                        .listRowBackground(Color.sobrCard)

                    Link("Support Resources", destination: URL(string: "https://findtreatment.gov")!)
                        .foregroundStyle(Color.sobrAccent)
                        .listRowBackground(Color.sobrCard)

                    Text("Support Resources opens findtreatment.gov. Sobr doesn't provide medical advice.")
                        .font(.footnote)
                        .foregroundStyle(Color.sobrSecondary)
                        .listRowBackground(Color.sobrCard)

                    Text(versionText)
                        .font(.footnote)
                        .foregroundStyle(Color.sobrSecondary)
                        .listRowBackground(Color.sobrCard)
                } header: {
                    Text("About")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .sobrScreen()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.sobrBg, for: .navigationBar)
        }
        .confirmationDialog(
            "Delete all data?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                store.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every logged day and both goals from this iPhone.")
        }
        .onAppear {
            if model == nil {
                model = SettingsViewModel(store: store)
            }
            Task { await model?.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model?.refresh() }
            }
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
