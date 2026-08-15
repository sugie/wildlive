// WildLive — First-time registration form.
//
// Apple-defaults render: Form + Section + TextField + `.borderedProminent`
// primary button. Shown after START on first launch (no persisted session).

import SwiftUI

struct RegistrationView: View {
    @Environment(AppStore.self) private var store

    @State private var displayName: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Display name", text: $displayName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($nameFieldFocused)
                    .disabled(isSubmitting)
                    .accessibilityIdentifier("displayNameField")
            } header: {
                Text("Register")
            } footer: {
                Text("Pick any name (2–32 characters). You can change it later.")
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().controlSize(.small)
                        }
                        Text(isSubmitting ? "Registering…" : "Register")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSubmit)
                .accessibilityIdentifier("registerButton")
            }
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { nameFieldFocused = true }
        .alert("Registration failed", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .accessibilityIdentifier("registrationView")
    }

    private var trimmed: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !isSubmitting && trimmed.count >= 2 && trimmed.count <= 32
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        switch await store.register(displayName: trimmed) {
        case .success:
            break // AppStore transitions to Home
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { RegistrationView() }
        .environment(AppStore())
}
