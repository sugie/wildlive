// WildLive — First-time registration form.
//
// The View is a thin binding over RegistrationViewModel. It knows nothing
// about the API, UserDefaults, or the AppStore — the ViewModel talks to
// the RegisterPlayer use case, and a closure the ViewModel was
// constructed with pushes the result into whichever state container the
// composition root supplied.

import SwiftUI

struct RegistrationView: View {
    @State var viewModel: RegistrationViewModel
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Display name", text: $viewModel.displayName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($nameFieldFocused)
                    .disabled(viewModel.isSubmitting)
                    .accessibilityIdentifier("displayNameField")
            } header: {
                Text("Register")
            } footer: {
                Text("Pick any name (2–32 characters). You can change it later.")
            }

            Section {
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView().controlSize(.small)
                        }
                        Text(viewModel.isSubmitting ? "Registering…" : "Register")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("registerButton")
            }
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { nameFieldFocused = true }
        .alert("Registration failed", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .accessibilityIdentifier("registrationView")
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
