import SwiftUI

@MainActor
struct GoalEditorSheet: View {
    @Environment(DrinkStore.self) private var store
    let period: GoalPeriod
    let existing: GoalRecord?

    var body: some View {
        GoalEditorContainer(model: GoalEditorViewModel(period: period, existing: existing, store: store))
    }
}

@MainActor
private struct GoalEditorContainer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: GoalEditorViewModel
    @State private var confirmDelete = false

    init(model: GoalEditorViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                if model.isCreating {
                    Picker("Period", selection: $model.period) {
                        Text("Week").tag(GoalPeriod.week)
                        Text("Month").tag(GoalPeriod.month)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.sobrCard)
                    .onChange(of: model.period) { _, _ in
                        model.applyPeriodChange()
                    }
                }

                Stepper(value: $model.maxDrinks, in: model.stepperRange) {
                    Text("Max drinks: \(model.maxDrinks)")
                        .foregroundStyle(Color.sobrLabel)
                        .monospacedDigit()
                }
                .listRowBackground(Color.sobrCard)
                .sensoryFeedback(.selection, trigger: model.maxDrinks)

                if !model.isCreating {
                    Button("Delete Goal") {
                        confirmDelete = true
                    }
                    .foregroundStyle(Color.sobrDestructive)
                    .listRowBackground(Color.sobrCard)
                }
            }
            .scrollContentBackground(.hidden)
            .sobrScreen()
            .navigationTitle(model.isCreating ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.save() }
                        .fontWeight(.bold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(model.footer)
                    .font(.footnote)
                    .foregroundStyle(Color.sobrSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .confirmationDialog(
            "Delete this goal?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Goal", role: .destructive) {
                model.delete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your logged drinks stay. Only this limit is removed.")
        }
        .onChange(of: model.saveToken) { _, token in
            if token > 0 { dismiss() }
        }
    }
}
