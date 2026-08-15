// WildLive — Presentation-layer state holder for RegistrationView.
//
// Owns display-name input, submission state, and error text. Calls the
// RegisterPlayer use case; on success, hands the result to an injected
// closure so this ViewModel stays independent of AppStore.
//
// Presentation-only: does NOT touch URLSession, UserDefaults, APIClient,
// or any Data-layer type directly.

import Foundation
import Observation

@Observable
final class RegistrationViewModel {
    // Inputs / UI state
    var displayName: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    // Wiring
    private let registerPlayer: RegisterPlayer
    private let onSuccess: (RegisteredPlayer) -> Void

    init(
        registerPlayer: RegisterPlayer,
        onSuccess: @escaping (RegisteredPlayer) -> Void
    ) {
        self.registerPlayer = registerPlayer
        self.onSuccess = onSuccess
    }

    // MARK: Derived

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !isSubmitting && trimmedDisplayName.count >= 2 && trimmedDisplayName.count <= 32
    }

    // MARK: Actions

    /// Attempt registration. Prevents re-entry while a submission is in
    /// flight. On success, notifies the injected closure and clears any
    /// prior error; on failure, exposes the error's `localizedDescription`.
    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let registered = try await registerPlayer(
                RegisterPlayerInput(displayName: trimmedDisplayName)
            )
            errorMessage = nil
            onSuccess(registered)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
