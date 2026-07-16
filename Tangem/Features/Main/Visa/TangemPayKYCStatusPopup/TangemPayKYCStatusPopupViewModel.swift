//
//  TangemPayKYCStatusPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI
import TangemLocalization
import TangemAssets
import let TangemVisa.VisaLogger
import TangemPay
import TangemAccessibilityIdentifiers

final class TangemPayKYCStatusPopupViewModel: TangemPayPopupViewModel {
    @Injected(\.alertPresenter)
    private var alertPresenter: AlertPresenter

    let tangemPayKYCInteractor: TangemPayKYCInteractor
    weak var coordinator: TangemPayKYCStatusRoutable?

    var title: AttributedString {
        .init(Localization.tangempayKycInProgress)
    }

    var description: AttributedString {
        .init(Localization.tangempayKycInProgressPopupDescription)
    }

    var icon: Image {
        DesignSystem.Icons.Clock.regular32.image
    }

    var primaryButton: MainButton.Settings {
        .init(title: Localization.tangempayCancelKyc, style: .primary, action: showAlert)
    }

    var secondaryButton: MainButton.Settings? {
        .init(title: Localization.tangempayKycInProgressNotificationButton, style: .secondary, action: viewStatus)
    }

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.kycStatusSheetPrimaryButton
    }

    init(
        tangemPayKYCInteractor: TangemPayKYCInteractor,
        coordinator: TangemPayKYCStatusRoutable?
    ) {
        self.tangemPayKYCInteractor = tangemPayKYCInteractor
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeKYCStatusPopup()
    }

    private func viewStatus() {
        coordinator?.closeKYCStatusPopup()
        runTask { [tangemPayKYCInteractor] in
            do {
                try await tangemPayKYCInteractor.launchKYC()
            } catch {
                VisaLogger.error("Failed to launch KYC", error: error)
            }
        }
    }

    private func showAlert() {
        let alert = AlertBuilder.makeAlert(
            title: Localization.tangempayKycConfirmCancellationAlertTitle,
            message: Localization.tangempayKycConfirmCancellationDescription,
            primaryButton: .cancel(Text(Localization.commonNotNow)),
            secondaryButton: .default(
                Text(Localization.commonConfirm),
                action: { [weak self] in
                    self?.cancelKYC()
                }
            )
        )

        alertPresenter.present(alert: alert)
    }

    private func cancelKYC() {
        tangemPayKYCInteractor.cancelKYC { [weak self] succeeded in
            succeeded ? self?.dismiss() : self?.showSomethingWentWrong()
        }
    }

    private func showSomethingWentWrong() {
        Task { @MainActor in
            Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
                .present(
                    layout: .top(padding: 20),
                    type: .temporary()
                )
        }
    }
}
