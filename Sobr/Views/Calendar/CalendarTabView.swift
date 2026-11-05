import SwiftUI

@MainActor
struct CalendarTabView: View {
    @Environment(DrinkStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var visibleMonth = CalendarMath.startOfMonth(for: Date())
    @State private var today = Date()
    @State private var logSelection: LogSelection?

    private var model: CalendarViewModel {
        CalendarViewModel(store: store, visibleMonth: visibleMonth, today: today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    streakCard
                    calendarCard
                    summaryCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            .sobrScreen()
            .navigationTitle("Sobr")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        withAnimation(.snappy) {
                            today = Date()
                            visibleMonth = CalendarMath.startOfMonth(for: today)
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.sobrBg, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                logTodayBar
            }
        }
        .sheet(item: $logSelection) { selection in
            LogDaySheet(date: selection.date)
        }
        .onAppear { today = Date() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                today = Date()
            }
        }
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(model.streakValue)")
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.sobrLabel)
            Text(model.streakUnit)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.sobrSecondary)
            Text(model.streakSubtitle)
                .font(.footnote)
                .foregroundStyle(Color.sobrSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sobrCard()
        .accessibilityElement(children: .combine)
    }

    private var calendarCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(model.monthTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.sobrLabel)
                Spacer()
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.sobrAccent)
                .accessibilityLabel("Previous month")

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(model.canAdvance ? Color.sobrAccent : Color.sobrTertiary)
                .disabled(!model.canAdvance)
                .accessibilityLabel("Next month")
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(model.weekdayHeaders.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sobrSecondary)
                        .frame(maxWidth: .infinity, minHeight: 20)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(model.days) { day in
                    dayCell(day)
                }
            }
        }
        .sobrCard()
        .gesture(monthSwipe)
    }

    private func dayCell(_ day: MonthDay) -> some View {
        Group {
            if let date = day.date, !day.isFuture {
                Button {
                    logSelection = LogSelection(date: date)
                } label: {
                    dayLabel(day)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.accessibilityLabel(for: day))
                .accessibilityHint("Opens the drink log")
            } else {
                dayLabel(day)
                    .accessibilityLabel(model.accessibilityLabel(for: day))
                    .accessibilityHidden(day.date == nil)
            }
        }
    }

    private func dayLabel(_ day: MonthDay) -> some View {
        VStack(spacing: 2) {
            Text(day.number)
                .font(.system(.body, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(dayForeground(day))
                .frame(width: 36, height: 36)
                .background {
                    if day.isLogged {
                        Circle().fill(Color.sobrAccent)
                    }
                }
                .overlay {
                    if day.isToday {
                        Circle()
                            .strokeBorder(Color.sobrAccent, lineWidth: day.isLogged ? 0 : 1.5)
                            .padding(day.isLogged ? 0 : 0)
                    }
                }
                .overlay {
                    if day.isToday && day.isLogged {
                        Circle()
                            .strokeBorder(Color.sobrAccent, lineWidth: 2)
                            .padding(-4)
                    }
                }
            Text(day.isLogged ? "\(day.count)" : " ")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.sobrAccent)
                .frame(height: 14)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .contentShape(Rectangle())
    }

    private func dayForeground(_ day: MonthDay) -> Color {
        if day.date == nil { return .clear }
        if day.isLogged { return Color.sobrOnAccent }
        if day.isFuture { return Color.sobrTertiary }
        return Color.sobrLabel
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.glanceTitle)
                .font(.headline)
                .foregroundStyle(Color.sobrLabel)

            HStack(spacing: 0) {
                GlanceStat(value: model.drinkTotal, label: "Drinks")
                GlanceStat(value: model.drinkingDays, label: "Drinking days")
                GlanceStat(value: model.alcoholFreeDays, label: "Alcohol-free")
            }

            if model.isCurrentMonth, model.weekMax != nil {
                GoalProgressBar(title: "This week", total: model.weekTotal, maximum: model.weekMax)
            }
            if model.monthMax != nil {
                GoalProgressBar(
                    title: model.isCurrentMonth ? "This month" : visibleMonth.formatted(.dateTime.month(.wide)),
                    total: model.drinkTotal,
                    maximum: model.monthMax
                )
            }
            if let status = model.statusLine {
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(model.statusIsWarning ? Color.sobrWarning : Color.sobrSecondary)
            }
        }
        .sobrCard()
    }

    private var logTodayBar: some View {
        VStack(spacing: 0) {
            PrimaryButton(title: model.logTodayTitle) {
                today = Date()
                logSelection = LogSelection(date: today)
            }
            .accessibilityIdentifier("logToday")
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if value.translation.width < -40 {
                    shiftMonth(by: 1)
                } else if value.translation.width > 40 {
                    shiftMonth(by: -1)
                }
            }
    }

    private func shiftMonth(by value: Int) {
        guard value < 0 || model.canAdvance else { return }
        guard let next = Calendar.current.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        withAnimation(.snappy) {
            visibleMonth = CalendarMath.startOfMonth(for: next)
        }
    }
}

private struct LogSelection: Identifiable {
    let date: Date
    var id: String { DateKey.string(from: date) }
}
