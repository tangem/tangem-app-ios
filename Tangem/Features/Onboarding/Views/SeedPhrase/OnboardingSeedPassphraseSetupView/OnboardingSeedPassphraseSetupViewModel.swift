//
//  OnboardingSeedPassphraseSetupViewModel.swift
//  Tangem
//
//  Created by Dean Rie on 28.09.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemMobileWalletSdk

/// Optional BIP-39 passphrase for a wallet that is being *created* (as opposed to imported).
///
/// Off by default: the passphrase is a second secret that is lost far more often than the seed phrase,
/// so it is an explicit opt-in behind a toggle, has to be typed twice, and comes with a warning.
final class OnboardingSeedPassphraseSetupViewModel: ObservableObject {
    @Published var isEnabled = false
    @Published var passphrase = ""
    @Published var confirmation = ""
    @Published var isPassphraseInputResponder: Bool? = nil
    @Published var isConfirmationInputResponder: Bool? = nil
    @Published var infoBottomSheetModel: OnboardingSeedPassphraseInfoBottomSheetModel? = nil

    @Published private(set) var errorMessage: String? = nil
    /// `true` when the toggle is off, or when both fields hold the same valid passphrase.
    @Published private(set) var isValid = true

    /// Shown for the mobile wallet: a passphrase-protected mobile wallet cannot be upgraded to a card.
    let showsMobileUpgradeNote: Bool

    /// The passphrase to derive with, or `nil` when the user did not opt in.
    var resolvedPassphrase: String? {
        guard isEnabled, isValid, !passphrase.isEmpty else {
            return nil
        }

        return passphrase
    }

    private var bag: Set<AnyCancellable> = []

    init(showsMobileUpgradeNote: Bool) {
        self.showsMobileUpgradeNote = showsMobileUpgradeNote
        bind()
    }

    func openInfo() {
        let wasPassphraseResponder = isPassphraseInputResponder
        let wasConfirmationResponder = isConfirmationInputResponder
        isPassphraseInputResponder = nil
        isConfirmationInputResponder = nil

        infoBottomSheetModel = .init(actionHandler: { [weak self] in
            self?.infoBottomSheetModel = nil
            // Give the sheet time to dismiss before the keyboard comes back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.isPassphraseInputResponder = wasPassphraseResponder
                self?.isConfirmationInputResponder = wasConfirmationResponder
            }
        })
    }

    private func bind() {
        Publishers.CombineLatest3($isEnabled, $passphrase, $confirmation)
            .map { isEnabled, passphrase, confirmation -> (isValid: Bool, error: String?) in
                guard isEnabled else {
                    return (true, nil)
                }

                do {
                    try PassphraseValidator.validate(passphrase: passphrase)
                } catch PassphraseValidator.ValidationError.tooLong(let maxByteCount) {
                    return (false, Localization.hwImportSeedPhrasePassphraseTooLong(maxByteCount))
                } catch {
                    return (false, error.localizedDescription)
                }

                guard !passphrase.isEmpty else {
                    return (false, nil)
                }

                guard confirmation == passphrase else {
                    // Only complain once the user has typed at least as much as the passphrase.
                    let showsMismatch = confirmation.count >= passphrase.count
                    return (false, showsMismatch ? Localization.onboardingSeedPassphraseSetupMismatch : nil)
                }

                return (true, nil)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isValid = result.isValid
                self?.errorMessage = result.error
            }
            .store(in: &bag)

        // Turning the option off discards whatever was typed so nothing stale is derived with later.
        $isEnabled
            .dropFirst()
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.passphrase = ""
                self?.confirmation = ""
                self?.isPassphraseInputResponder = nil
                self?.isConfirmationInputResponder = nil
            }
            .store(in: &bag)
    }
}
