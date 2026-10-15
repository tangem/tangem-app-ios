//
//  TangemPayRegionUnavailablePopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemFoundation
import TangemLocalization
import TangemAssets

protocol TangemPayRegionUnavailableRoutable: AnyObject {
    func closeTangemPayRegionUnavailablePopup()
    func openTangemPayRegionReselection(interactor: any TangemPayResidencyInteractor)
}

final class TangemPayRegionUnavailablePopupViewModel: TangemPayPopupViewModel {
    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    private let region: TangemPayUnavailableRegion
    private let interactor: any TangemPayResidencyInteractor
    private weak var coordinator: TangemPayRegionUnavailableRoutable?

    var primaryButton: MainButton.Settings {
        .init(title: Localization.moneyAccountMainStatusDialogHideAccount, style: .primary, action: hideAccount)
    }

    var secondaryButton: MainButton.Settings? {
        .init(title: Localization.tangempayRegionUnavailableSecondaryButton, style: .secondary, action: selectAnotherRegion)
    }

    var title: AttributedString {
        .init(Localization.moneyAccountMainStatusDialogCountryNotSupportedTitle)
    }

    var description: AttributedString {
        var start = AttributedString(Localization.moneyAccountMainStatusDialogCountryNotSupportedDescription + " ")
        start.foregroundColor = Colors.Text.secondary

        var end = AttributedString(Localization.commonContactSupport)
        end.link = URL(string: "blank:url")
        end.foregroundColor = Colors.Text.primary1

        return start + end
    }

    var icon: Image {
        DesignSystem.Icons.HeartBroken.regular32.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .error
    }

    init(
        region: TangemPayUnavailableRegion,
        interactor: any TangemPayResidencyInteractor,
        coordinator: TangemPayRegionUnavailableRoutable
    ) {
        self.region = region
        self.interactor = interactor
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeTangemPayRegionUnavailablePopup()
    }

    func onHyperLinkTap(_ link: URL) {
        dismiss()

        let logsComposer = LogsComposer(
            infoProvider: TangemPayKYCDeclinedDataCollector(customerId: interactor.customerId),
            includeSystemLogs: false
        )
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.paeraDefault(subject: .regionUnavailable).recipient,
            emailType: .paeraSupport(subject: .regionUnavailable)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    private func selectAnotherRegion() {
        coordinator?.openTangemPayRegionReselection(interactor: interactor)
    }

    private func hideAccount() {
        dismiss()
        interactor.hideAccountFromHome()
    }
}
