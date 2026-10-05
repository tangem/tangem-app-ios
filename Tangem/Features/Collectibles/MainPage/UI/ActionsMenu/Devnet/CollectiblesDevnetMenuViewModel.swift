//
//  CollectiblesDevnetMenuViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import class UIKit.UIPasteboard
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemCollectibles

// [REDACTED_TODO_COMMENT]
// in this folder; the rest of the app holds one property and two lines of view code.
@MainActor
final class CollectiblesDevnetMenuViewModel: ObservableObject {
    // MARK: - Properties

    private let actions: any CollectiblesDevnetActions
    private let onAccountClosed: () -> Void

    private static var closeTask: Task<Void, Never>?

    // MARK: - Publishers

    @Published var alert: AlertBinder?
    @Published private(set) var isClosing = false

    // MARK: - Init

    init(actions: any CollectiblesDevnetActions, onAccountClosed: @escaping () -> Void) {
        self.actions = actions
        self.onAccountClosed = onAccountClosed
    }

    // MARK: - Methods

    func onCopyTopUpAddressTap() {
        Task { [actions] in
            do {
                let address = try await actions.topUpAddress()

                UIPasteboard.general.string = address
                Self.present(SuccessToast(text: Localization.commonValueCopied))
            } catch {
                CollectiblesLogger.error("Devnet: the top-up address could not be read", error: error)
                Self.present(WarningToast(text: Localization.commonSomethingWentWrong))
            }
        }
    }

    func onCopyFeePayerAddressTap() {
        do {
            UIPasteboard.general.string = try actions.feePayerAddress()
            Self.present(SuccessToast(text: Localization.commonValueCopied))
        } catch {
            CollectiblesLogger.error("Devnet: the fee payer address could not be read", error: error)
            Self.present(WarningToast(text: Localization.commonSomethingWentWrong))
        }
    }

    func onCopyPurchaseFeePayerAddressTap() {
        do {
            UIPasteboard.general.string = try actions.purchaseFeePayerAddress()
            Self.present(SuccessToast(text: Localization.commonValueCopied))
        } catch {
            CollectiblesLogger.error("Devnet: the purchase fee payer address could not be read", error: error)
            Self.present(WarningToast(text: Localization.commonSomethingWentWrong))
        }
    }

    func onCloseAccountTap() {
        guard Self.closeTask == nil else {
            return
        }

        alert = makeConfirmationAlert()
    }
}

// MARK: - Private implementation

private extension CollectiblesDevnetMenuViewModel {
    func makeConfirmationAlert() -> AlertBinder {
        let alert = Alert(
            title: Text(Constants.confirmationTitle),
            message: Text(Constants.confirmationMessage),
            primaryButton: .destructive(Text(Constants.confirmationAction)) { [weak self] in
                self?.closeAccount()
            },
            secondaryButton: .cancel(Text(Localization.commonCancel))
        )

        return AlertBinder(alert: alert)
    }

    /// The close spans a signature, a send that idles before it leaves, and the wait for the chain to catch up.
    /// The menu is reachable the whole time, so a second tap would send a second transaction against a vault
    /// that is already closing.
    func closeAccount() {
        isClosing = true

        Self.closeTask = Task { [weak self, actions] in
            defer {
                Self.closeTask = nil
                self?.isClosing = false
            }

            do {
                let outcome = try await actions.closeVault()

                switch outcome {
                case .confirmed:
                    Self.present(SuccessToast(text: Constants.closedText))
                    self?.onAccountClosed()
                case .submitted:
                    Self.present(WarningToast(text: Constants.closeSubmittedText))
                }
            } catch {
                CollectiblesLogger.error("Devnet: the vault could not be closed", error: error)
                Self.present(WarningToast(text: Localization.commonSomethingWentWrong))
            }
        }
    }

    static func present(_ toast: some View) {
        Toast(view: toast).present(layout: .top(padding: Constants.toastPadding), type: .temporary())
    }

    enum Constants {
        static let toastPadding: CGFloat = 14
        static let confirmationTitle = "Close account?"
        static let confirmationMessage = "The vault will be closed on chain. You can create the account again afterwards."
        static let confirmationAction = "Close"
        static let closedText = "Account closed"
        static let closeSubmittedText = "Close sent, the account clears shortly"
    }
}
