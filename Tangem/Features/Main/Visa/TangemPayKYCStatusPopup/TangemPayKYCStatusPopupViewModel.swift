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
        isRedesigned
            ? DesignSystem.Icons.Clock.regular32.image
            : Assets.Visa.promo.image
    }

    var primaryButton: MainButton.Settings {
        isRedesigned
            ? .init(title: Localization.tangempayCancelKyc, style: .primary, action: showAlert)
            : .init(title: Localization.tangempayKycInProgressNotificationButton, style: .primary, action: viewStatus)
    }

    var secondaryButton: MainButton.Settings? {
        isRedesigned
            ? .init(title: Localization.tangempayKycInProgressNotificationButton, style: .secondary, action: viewStatus)
            : .init(title: Localization.tangempayCancelKyc, style: .secondary, action: showAlert)
    }

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.kycStatusSheetPrimaryButton
    }

    private var isRedesigned: Bool {
        FeatureProvider.isAvailable(.tangemPaySpendRedesign)
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
