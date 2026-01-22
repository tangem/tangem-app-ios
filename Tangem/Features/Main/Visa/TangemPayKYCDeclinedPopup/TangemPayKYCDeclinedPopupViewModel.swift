//
//  TangemPayKYCDeclinedPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization
import TangemPay

final class TangemPayKYCDeclinedPopupViewModel {
    @Injected(\.alertPresenterViewModel)
    private var alertPresenterViewModel: AlertPresenterViewModel

    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    let tangemPayManager: TangemPayManager
    weak var coordinator: TangemPayKYCDeclinedRoutable?

    init(
        tangemPayManager: TangemPayManager,
        coordinator: TangemPayKYCDeclinedRoutable
    ) {
        self.tangemPayManager = tangemPayManager
        self.coordinator = coordinator
    }

    var openSupportButton: MainButton.Settings {
        .init(
            title: Localization.tangempayGoToSupport,
            style: .primary,
            action: openSupport
        )
    }

    var hideKYCButton: MainButton.Settings {
        .init(
            title: Localization.tangempayCancelKyc,
            style: .secondary,
            action: hideKYC
        )
    }

    func dismiss() {
        coordinator?.closeKYCDeclinedPopup()
    }

    private func openSupport() {
        dismiss()
        let logsComposer = LogsComposer(
            infoProvider: TangemPayKYCDeclinedDataCollector(
                customerId: tangemPayManager.customerId
            ),
            includeZipLogs: false
        )
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.paeraDefault(subject: .KYCRejected).recipient,
            emailType: .paeraSupport(subject: .KYCRejected)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    private func hideKYC() {
        tangemPayManager.cancelKYC { [weak self] succeeded in
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

extension TangemPayKYCDeclinedPopupViewModel: FloatingSheetContentViewModel {
    var id: String {
        String(describing: self)
    }
}
