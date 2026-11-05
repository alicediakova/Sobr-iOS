import SwiftUI

@MainActor
struct LogDaySheet: View {
    @Environment(DrinkStore.self) private var store
    let date: Date

    var body: some View {
        LogDayContainer(model: LogDayViewModel(date: date, store: store))
    }
}

@MainActor
private struct LogDayContainer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: LogDayViewModel

    init(model: LogDayViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    DrinkStepper(
                        count: $model.draft,
                        range: 0...30,
                        caption: "drinks",
                        numberSize: 84
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        GoalProgressBar(title: "This week", total: model.weekTotal, maximum: model.weekMax)
                        GoalProgressBar(title: "This month", total: model.monthTotal, maximum: model.monthMax)
                    }
                    .sobrCard()

                    if !model.message.isEmpty {
                        Text(model.message)
                            .font(.subheadline)
                            .foregroundStyle(model.messageIsWarning ? Color.sobrWarning : Color.sobrSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if model.wasLogged {
                        Button("Clear Day") {
                            model.clearDay()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.sobrDestructive)
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle(model.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.save() }
                        .fontWeight(.bold)
                        .accessibilityIdentifier("saveDay")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .sensoryFeedback(.success, trigger: model.saveToken)
        .onChange(of: model.saveToken) { _, token in
            if token > 0 {
                dismiss()
            }
        }
    }
}
