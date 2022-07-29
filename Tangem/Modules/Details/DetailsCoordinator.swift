//
//  DetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

class DetailsCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var detailsViewModel: DetailsViewModel? = nil

    // MARK: - Child coordinators
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var walletConnectCoordinator: WalletConnectCoordinator? = nil
    @Published var scanCardSettingsCoordinator: ScanCardSettingsCoordinator? = nil
    @Published var appSettingsCoordinator: AppSettingsCoordinator? = nil

    // MARK: - Child view models
    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var cardOperationViewModel: CardOperationViewModel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil

    // MARK: - Helpers
    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: DetailsCoordinator.Options) {
        detailsViewModel = DetailsViewModel(cardModel: options.cardModel, coordinator: self)
    }
}

extension DetailsCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

extension DetailsCoordinator: DetailsRoutable {
    func openCurrencySelection(autoDismiss: Bool) {
        currencySelectViewModel = CurrencySelectViewModel()
        currencySelectViewModel?.dismissAfterSelection = autoDismiss
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, support: EmailSupport, emailType: EmailType) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: support, emailType: emailType)
    }

    func openWalletConnect(with cardModel: CardViewModel) {
        let coordinator = WalletConnectCoordinator()
        let options = WalletConnectCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        walletConnectCoordinator = coordinator
    }

    func openDisclaimer() {
        disclaimerViewModel = .init(style: .navbar, showAccept: false, coordinator: nil)
    }

    func openCardTOU(at url: URL) {
        pushedWebViewModel = WebViewContainerViewModel(url: url, title: "details_row_title_card_tou".localized)
    }

    func openResetToFactory(action: @escaping (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void) {
        cardOperationViewModel = CardOperationViewModel(title: "details_row_title_reset_factory_settings".localized,
                                                        buttonTitle: "card_operation_button_title_reset",
                                                        shouldPopToRoot: true,
                                                        alert: "details_row_title_reset_factory_settings_warning".localized,
                                                        actionButtonPressed: action,
                                                        coordinator: self)
    }

    func openScanCardSettings() {
        let coordinator = ScanCardSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .default)
        scanCardSettingsCoordinator = coordinator
    }

    func openAppSettings() {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .default)
        appSettingsCoordinator = coordinator
    }

    func openSupportChat() {
        supportChatViewModel = SupportChatViewModel()
    }

    func openInSafari(url: URL) {
        UIApplication.shared.open(url)
    }
}

extension DetailsCoordinator: CardOperationRoutable {
    func dismissCardOperation() {
        cardOperationViewModel = nil
    }
}
