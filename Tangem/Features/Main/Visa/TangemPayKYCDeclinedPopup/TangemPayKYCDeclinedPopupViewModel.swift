//
//  TangemPayKYCDeclinedPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets
import TangemPay

final class TangemPayKYCDeclinedPopupViewModel: TangemPayPopupViewModel {
    @Injected(\.alertPresenterViewModel)
    private var alertPresenterViewModel: AlertPresenterViewModel

    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    let tangemPayManager: TangemPayManager
    weak var coordinator: TangemPayKYCDeclinedRoutable?

    var primaryButton: MainButton.Settings {
        .init(
            title: Localization.tangempayGoToSupport,
            style: .primary,
            action: openSupport
        )
    }

    var secondaryButton: MainButton.Settings? {
        .init(
            title: Localization.tangempayCancelKyc,
            style: .secondary,
            action: hideKYC
        )
    }

    var title: AttributedString {
        .init(Localization.tangempayKycRejected)
    }

    var description: AttributedString {
        var start = AttributedString(Localization.tangempayKycRejectedDescription + " ")
        start.foregroundColor = Colors.Text.secondary

        var end = AttributedString(Localization.tangempayKycRejectedDescriptionSpan)
        end.link = URL(string: "blank:url")
        end.foregroundColor = Colors.Text.accent

        return start + end
    }

    var icon: Image {
        Assets.Visa.kycDeclinedBrokenHeart.image
    }

    init(
        tangemPayManager: TangemPayManager,
        coordinator: TangemPayKYCDeclinedRoutable
    ) {
        self.tangemPayManager = tangemPayManager
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeKYCDeclinedPopup()
    }

    func onHyperLinkTap(_ link: URL) {
        coordinator?.closeKYCDeclinedPopup()
        Task { try? await tangemPayManager.launchKYC() }
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
