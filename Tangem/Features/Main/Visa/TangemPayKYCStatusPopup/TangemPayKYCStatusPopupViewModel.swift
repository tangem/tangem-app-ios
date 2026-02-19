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
    @Injected(\.alertPresenterViewModel)
    private var alertPresenterViewModel: AlertPresenterViewModel

    let tangemPayKYCInteractor: TangemPayKYCInteractor
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
        alertPresenterViewModel.alert = AlertBuilder.makeAlert(
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
