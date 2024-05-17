//
//  UserWalletSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class UserWalletSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UserWalletSettingsViewModel?

    // MARK: - Child coordinators

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var walletConnectCoordinator: WalletConnectCoordinator?
    @Published var cardSettingsCoordinator: CardSettingsCoordinator?
    @Published var referralCoordinator: ReferralCoordinator?

    // MARK: - Child view models

    @Published var scanCardSettingsViewModel: ScanCardSettingsViewModel?
    @Published var disclaimerViewModel: DisclaimerViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with userWalletModel: Options) {
        rootViewModel = UserWalletSettingsViewModel(userWalletModel: userWalletModel, coordinator: self)
    }
}

// MARK: - Options

extension UserWalletSettingsCoordinator {
    typealias Options = UserWalletModel
}

// MARK: - UserWalletSettingsRoutable

extension UserWalletSettingsCoordinator: WalletDetailsRoutable {
    func openWalletConnect(with disabledLocalizedReason: String?) {
        let coordinator = WalletConnectCoordinator()
        let options = WalletConnectCoordinator.Options(disabledLocalizedReason: disabledLocalizedReason)
        coordinator.start(with: options)
        walletConnectCoordinator = coordinator
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil
            if result.isSuccessful {
                self?.dismiss()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openScanCardSettings(with cardScanner: CardScanner) {
        scanCardSettingsViewModel = ScanCardSettingsViewModel(cardScanner: cardScanner, coordinator: self)
    }

    func openDisclaimer(at url: URL) {
        disclaimerViewModel = .init(url: url, style: .details)
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
}

// MARK: - ScanCardSettingsRoutable

extension WalletDetailsCoordinator: ScanCardSettingsRoutable {
    func openCardSettings(with input: CardSettingsViewModel.Input) {
        scanCardSettingsViewModel = nil

        let coordinator = CardSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(input: input))
        cardSettingsCoordinator = coordinator
    }
}
