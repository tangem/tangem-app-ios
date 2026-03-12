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

final class TangemPayKYCStatusPopupViewModel: TangemPayPopupViewModel {
    @Injected(\.alertPresenter)
    private var alertPresenter: AlertPresenter

    let paymentAccountKYCInteractor: PaymentAccountKYCInteractor
    weak var coordinator: TangemPayKYCStatusRoutable?

    var title: AttributedString {
        .init(Localization.tangempayKycInProgress)
    }

    var description: AttributedString {
        .init(Localization.tangempayKycInProgressPopupDescription)
    }

    var icon: Image {
        Assets.Visa.promo.image
    }

    var primaryButton: MainButton.Settings {
        .init(
            title: Localization.tangempayKycInProgressNotificationButton,
            style: .primary,
            action: viewStatus
        )
    }

    var secondaryButton: MainButton.Settings? {
        .init(
            title: Localization.tangempayCancelKyc,
            style: .secondary,
            action: showAlert
        )
    }

    init(
        paymentAccountKYCInteractor: PaymentAccountKYCInteractor,
        coordinator: TangemPayKYCStatusRoutable?
    ) {
        self.paymentAccountKYCInteractor = paymentAccountKYCInteractor
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeKYCStatusPopup()
    }

    private func viewStatus() {
        coordinator?.closeKYCStatusPopup()
        runTask { [paymentAccountKYCInteractor] in
            do {
                try await paymentAccountKYCInteractor.launchKYC()
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
        paymentAccountKYCInteractor.cancelKYC { [weak self] succeeded in
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
