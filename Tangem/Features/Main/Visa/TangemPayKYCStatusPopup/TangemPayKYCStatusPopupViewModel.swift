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
import let TangemVisa.VisaLogger

final class TangemPayKYCStatusPopupViewModel {
    @Injected(\.alertPresenterViewModel)
    private var alertPresenterViewModel: AlertPresenterViewModel

    let tangemPayManager: TangemPayManager
    weak var coordinator: TangemPayKYCStatusRoutable?

    init(
        tangemPayManager: TangemPayManager,
        coordinator: TangemPayKYCStatusRoutable?
    ) {
        self.tangemPayManager = tangemPayManager
        self.coordinator = coordinator
    }

    var viewStatusSettings: MainButton.Settings {
        .init(
            title: Localization.tangempayKycInProgressNotificationButton,
            style: .primary,
            action: viewStatus
        )
    }

    var cancelKYCSettings: MainButton.Settings {
        .init(
            title: Localization.tangempayCancelKyc,
            style: .secondary,
            action: showAlert
        )
    }

    func dismiss() {
        coordinator?.closeKYCStatusPopup()
    }

    private func viewStatus() {
        coordinator?.closeKYCStatusPopup()
        runTask { [self] in
            do {
                try await tangemPayManager.paeraCustomer?.launchKYC {
                    self.tangemPayManager.refresh()
                }
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
        tangemPayManager.paeraCustomer?.cancelKYC { [weak self] succeeded in
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

extension TangemPayKYCStatusPopupViewModel: FloatingSheetContentViewModel {
    var id: String {
        String(describing: self)
    }
}
