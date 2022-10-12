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
    @Published var cardSettingsCoordinator: CardSettingsCoordinator? = nil
    @Published var appSettingsCoordinator: AppSettingsCoordinator? = nil

    // MARK: - Child view models

    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil
    @Published var scanCardSettingsViewModel: ScanCardSettingsViewModel?

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

// MARK: - DetailsRoutable

extension DetailsCoordinator: DetailsRoutable {
    func openCurrencySelection() {
        currencySelectViewModel = CurrencySelectViewModel()
        currencySelectViewModel?.dismissAfterSelection = false
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, shouldOpenMainOnFinish: false, saveUserWalletOnFinish: false)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, recipient: recipient, emailType: emailType)
    }

    func openWalletConnect(with cardModel: CardViewModel) {
        Analytics.log(.myWalletsScreenOpened)
        let coordinator = WalletConnectCoordinator()
        let options = WalletConnectCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        walletConnectCoordinator = coordinator
    }

    func openDisclaimer() {
        disclaimerViewModel = .init(style: .navbar, showAccept: false, coordinator: nil)
    }

    func openCardTOU(url: URL) {
        pushedWebViewModel = WebViewContainerViewModel(url: url, title: "details_row_title_card_tou".localized)
    }

    func openScanCardSettings() {
        scanCardSettingsViewModel = ScanCardSettingsViewModel(coordinator: self)
    }

    func openAppSettings(userWallet: UserWallet) {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .default(userWallet: userWallet))
        appSettingsCoordinator = coordinator
    }

    func openSupportChat(cardId: String, dataCollector: EmailDataCollector) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(cardId: cardId, dataCollector: dataCollector)
    }

    func openInSafari(url: URL) {
        UIApplication.shared.open(url)
    }
}

// MARK: - ScanCardSettingsRoutable

extension DetailsCoordinator: ScanCardSettingsRoutable {
    func openCardSettings(cardModel: CardViewModel) {
        scanCardSettingsViewModel = nil

        let coordinator = CardSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init(cardModel: cardModel))
        cardSettingsCoordinator = coordinator
    }
}
