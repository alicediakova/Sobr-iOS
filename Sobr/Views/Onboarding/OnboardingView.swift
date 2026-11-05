import SwiftUI

@MainActor
struct OnboardingView: View {
    @Environment(DrinkStore.self) private var store
    @State private var path: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcome {
                path.append(.goal)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .goal:
                    OnboardingGoal(
                        onContinue: { period, maxDrinks in
                            store.saveGoal(period: period, maxDrinks: maxDrinks)
                            path.append(.reminder)
                        },
                        onSkip: {
                            path.append(.reminder)
                        }
                    )
                case .reminder:
                    OnboardingReminder(
                        onFinish: { time, enable in
                            if let time {
                                store.updateReminderTime(time)
                            }
                            if enable {
                                store.setReminderEnabled(true)
                            }
                            store.completeOnboarding()
                            Task { await store.rescheduleNotifications() }
                        }
                    )
                }
            }
        }
        .tint(Color.sobrAccent)
    }
}

private enum OnboardingStep: Hashable {
    case goal
    case reminder
}

private struct OnboardingProgress: View {
    var step: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.sobrAccent : Color.sobrTrack)
                    .frame(width: index == step ? 22 : 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step + 1) of 3")
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

private struct OnboardingWelcome: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgress(step: 0)
            Spacer(minLength: 24)
            VStack(spacing: 16) {
                Image(systemName: "wineglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.sobrAccent)
                    .frame(width: 88, height: 88)
                    .background(Color.sobrAccentSoft, in: Circle())
                    .accessibilityHidden(true)

                Text("Sobr")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.sobrLabel)

                Text("Count your drinks. Stay under your goal.")
                    .font(.title3)
                    .foregroundStyle(Color.sobrSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer(minLength: 24)
            VStack(spacing: 16) {
                Text("No account. Your data stays on this iPhone.")
                    .font(.footnote)
                    .foregroundStyle(Color.sobrSecondary)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Get Started", action: onNext)
                    .accessibilityIdentifier("getStarted")
            }
            .padding(24)
        }
        .sobrScreen()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.sobrBg, for: .navigationBar)
    }
}

private struct OnboardingGoal: View {
    var onContinue: (GoalPeriod, Int) -> Void
    var onSkip: () -> Void

    @State private var period: GoalPeriod = .week
    @State private var maxDrinks = GoalPeriod.week.defaultMax

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgress(step: 1)
            ScrollView {
                VStack(spacing: 28) {
                    Text("What's your limit?")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.sobrLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Period", selection: $period) {
                        Text("Per Week").tag(GoalPeriod.week)
                        Text("Per Month").tag(GoalPeriod.month)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: period) { _, newPeriod in
                        maxDrinks = newPeriod.defaultMax
                    }

                    DrinkStepper(
                        count: $maxDrinks,
                        range: period.range,
                        caption: period.stepperCaption,
                        numberSize: 72
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .padding(24)
            }
            VStack(spacing: 8) {
                PrimaryButton(title: "Continue") {
                    onContinue(period, maxDrinks)
                }
                Button("Skip for now", action: onSkip)
                    .font(.body)
                    .foregroundStyle(Color.sobrAccent)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sobrScreen()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.sobrBg, for: .navigationBar)
    }
}

private struct OnboardingReminder: View {
    var onFinish: (Date?, Bool) -> Void

    @State private var time = DateKey.date(fromTime: "21:00")
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgress(step: 2)
            ScrollView {
                VStack(spacing: 20) {
                    Text("A nudge each evening?")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.sobrLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("One reminder a day, at the time you pick. It opens straight to today's log.")
                        .font(.body)
                        .foregroundStyle(Color.sobrSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DatePicker(
                        "Reminder time",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            VStack(spacing: 8) {
                PrimaryButton(title: isRequesting ? "Turning On…" : "Turn On Reminders") {
                    guard !isRequesting else { return }
                    isRequesting = true
                    Task {
                        let granted = await NotificationService.shared.requestAuthorization()
                        onFinish(time, granted)
                        isRequesting = false
                    }
                }
                .disabled(isRequesting)
                .accessibilityIdentifier("turnOnReminders")

                Button("Not Now") {
                    onFinish(nil, false)
                }
                .font(.body)
                .foregroundStyle(Color.sobrAccent)
                .frame(minHeight: 44)
                .disabled(isRequesting)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sobrScreen()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.sobrBg, for: .navigationBar)
    }
}
