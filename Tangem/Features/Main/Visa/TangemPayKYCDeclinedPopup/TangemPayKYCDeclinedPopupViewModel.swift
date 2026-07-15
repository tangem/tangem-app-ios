//
//  TangemPayKYCDeclinedPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemVisa
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemPay
import TangemAccessibilityIdentifiers

final class TangemPayKYCDeclinedPopupViewModel: TangemPayPopupViewModel {
    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    let tangemPayKYCInteractor: TangemPayKYCInteractor
    weak var coordinator: TangemPayKYCDeclinedRoutable?

    var primaryButton: MainButton.Settings {
        isRedesigned
            ? .init(title: Localization.tangempayKycRejectedButtonText, style: .primary, action: hideKYC)
            : .init(title: Localization.tangempayGoToSupport, style: .primary, action: openSupport)
    }

    var secondaryButton: MainButton.Settings? {
        isRedesigned
            ? .init(title: Localization.commonContactSupport, style: .secondary, action: openSupport)
            : .init(title: Localization.tangempayCancelKyc, style: .secondary, action: hideKYC)
    }

    var title: AttributedString {
        .init(Localization.tangempayKycRejected)
    }

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.kycDeclinedSheetPrimaryButton
    }

    var iconStyle: TangemPayPopupIconStyle {
        .error
    }

    private var isRedesigned: Bool {
        FeatureProvider.isAvailable(.tangemPaySpendRedesign)
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
        isRedesigned
            ? DesignSystem.Icons.HeartBroken.regular32.image
            : Assets.Visa.kycDeclinedBrokenHeart.image
    }

    init(
        tangemPayKYCInteractor: TangemPayKYCInteractor,
        coordinator: TangemPayKYCDeclinedRoutable
    ) {
        self.tangemPayKYCInteractor = tangemPayKYCInteractor
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeKYCDeclinedPopup()
    }

    func onHyperLinkTap(_ link: URL) {
        coordinator?.closeKYCDeclinedPopup()
        runTask(in: self) { viewModel in
            do {
                try await viewModel.tangemPayKYCInteractor.launchKYC()
            } catch {
                VisaLogger.error("Failed to launch KYC from hyperlink", error: error)
            }
        }
    }

    private func openSupport() {
        dismiss()
        let logsComposer = LogsComposer(
            infoProvider: TangemPayKYCDeclinedDataCollector(
                customerId: tangemPayKYCInteractor.customerId
            ),
            includeSystemLogs: false
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
