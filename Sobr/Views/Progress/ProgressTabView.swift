import SwiftUI

@MainActor
struct ProgressTabView: View {
    @Environment(DrinkStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var today = Date()
    @State private var goalRoute: GoalRoute?
    @State private var selectedWeekKey: String?

    private var model: ProgressViewModel {
        ProgressViewModel(store: store, today: today)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Goals") {
                    goalLink(period: .week, existing: model.weekGoal)
                    goalLink(period: .month, existing: model.monthGoal)
                }

                Section("This Period") {
                    VStack(alignment: .leading, spacing: 14) {
                        GoalProgressBar(
                            title: "This week",
                            total: model.weekTotal,
                            maximum: model.weekGoal?.maxDrinks
                        )
                        GoalProgressBar(
                            title: "This month",
                            total: model.monthTotal,
                            maximum: model.monthGoal?.maxDrinks
                        )
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.sobrCard)
                }

                Section("Last 8 Weeks") {
                    WeekChartView(
                        weeks: model.weeks,
                        goal: model.weekGoal?.maxDrinks,
                        selectedKey: $selectedWeekKey
                    )
                    .padding(.vertical, 8)
                    .listRowBackground(Color.sobrCard)
                }

                Section("Totals") {
                    totalRow("Current streak", value: dayLabel(model.currentStreak))
                    totalRow("Longest streak", value: dayLabel(model.longestStreak))
                    totalRow("Alcohol-free days", value: "\(model.alcoholFreeDays) this month")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .sobrScreen()
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.sobrBg, for: .navigationBar)
        }
        .sheet(item: $goalRoute) { route in
            GoalEditorSheet(period: route.period, existing: route.existing)
        }
        .onAppear { today = Date() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = Date() }
        }
    }

    private func goalLink(period: GoalPeriod, existing: GoalRecord?) -> some View {
        Button {
            goalRoute = GoalRoute(period: period, existing: existing)
        } label: {
            HStack {
                Text(existing.map(model.goalRowTitle) ?? (period == .week ? "Add weekly goal" : "Add monthly goal"))
                    .foregroundStyle(Color.sobrLabel)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.sobrTertiary)
            }
        }
        .listRowBackground(Color.sobrCard)
    }

    private func totalRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.sobrLabel)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.sobrSecondary)
        }
        .listRowBackground(Color.sobrCard)
    }

    private func dayLabel(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }
}

struct GoalRoute: Identifiable {
    let period: GoalPeriod
    let existing: GoalRecord?
    var id: String { period.rawValue + (existing == nil ? "-new" : "-edit") }
}
