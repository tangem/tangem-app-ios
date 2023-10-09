//
//  DetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemSdk

class DetailsCoordinator: CoordinatorObject {
    var dismissAction: Action<DismissOptions>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var detailsViewModel: DetailsViewModel? = nil

    // MARK: - Child coordinators

    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var walletConnectCoordinator: WalletConnectCoordinator? = nil
    @Published var cardSettingsCoordinator: CardSettingsCoordinator? = nil
    @Published var appSettingsCoordinator: AppSettingsCoordinator? = nil
    @Published var referralCoordinator: ReferralCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil
    @Published var scanCardSettingsViewModel: ScanCardSettingsViewModel? = nil
    @Published var environmentSetupCoordinator: EnvironmentSetupCoordinator? = nil

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<DismissOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: DetailsCoordinator.Options) {
        detailsViewModel = DetailsViewModel(userWalletModel: options.userWalletModel, coordinator: self)
    }
}

extension DetailsCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }

    struct DismissOptions {
        let isNewCardAdded: Bool
    }
}

// MARK: - DetailsRoutable

extension DetailsCoordinator: DetailsRoutable {
    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil
            if result.isSuccessful {
                self?.dismiss(with: .init(isNewCardAdded: false))
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openWalletConnect(with disabledLocalizedReason: String?) {
        let coordinator = WalletConnectCoordinator()
        let options = WalletConnectCoordinator.Options(disabledLocalizedReason: disabledLocalizedReason)
        coordinator.start(with: options)
        walletConnectCoordinator = coordinator
    }

    func openDisclaimer(at url: URL) {
        disclaimerViewModel = .init(url: url, style: .details)
    }

    func openScanCardSettings(with userWalletId: Data, sdk: TangemSdk) {
        scanCardSettingsViewModel = ScanCardSettingsViewModel(expectedUserWalletId: userWalletId, sdk: sdk, coordinator: self)
    }

    func openAppSettings() {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())
        appSettingsCoordinator = coordinator
    }

    func openSupportChat(input: SupportChatInputModel) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openInSafari(url: URL) {
        UIApplication.shared.open(url)
    }

    func openEnvironmentSetup() {
        let coordinator = EnvironmentSetupCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())

        environmentSetupCoordinator = coordinator
    }

    func openReferral(input: ReferralInputModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.referralCoordinator = nil
        }

        let coordinator = ReferralCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(input: input))
        referralCoordinator = coordinator
        Analytics.log(.referralScreenOpened)
    }

    func finishScan(isNewCardAdded: Bool) {
        dismiss(with: .init(isNewCardAdded: isNewCardAdded))
    }
}

// MARK: - ScanCardSettingsRoutable

extension DetailsCoordinator: ScanCardSettingsRoutable {
    func openCardSettings(cardModel: CardViewModel) {
        scanCardSettingsViewModel = nil

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.dismissAction(.init(isNewCardAdded: false))
        }

        let coordinator = CardSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(cardModel: cardModel))
        cardSettingsCoordinator = coordinator
    }
}
