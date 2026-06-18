//
//  CreateWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class CreateWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: CreateWalletSelectorViewModel?
    @Published private(set) var rootPromoViewModel: CreateWalletSelectorPromoViewModel?
    @Published var onboardingCoordinator: OnboardingCoordinator?
    @Published var mobileCreateWalletCoordinator: MobileCreateWalletCoordinator?

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        if AppSettings.shared.shouldShowMobilePromoWalletSelector {
            rootPromoViewModel = CreateWalletSelectorPromoViewModel(coordinator: self, showsBackButton: options.showsBackButton)
        } else {
            rootViewModel = CreateWalletSelectorViewModel(coordinator: self, showsBackButton: options.showsBackButton)
        }
    }
}

// MARK: - CreateNewWalletSelectorRoutable

extension CreateWalletSelectorCoordinator: CreateWalletSelectorRoutable {
    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func openCreateMobileWallet() {
        let dismissAction: Action<MobileCreateWalletCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.mobileCreateWalletCoordinator = nil
            }
        }

        let coordinator = MobileCreateWalletCoordinator(dismissAction: dismissAction)
        coordinator.start(with: MobileCreateWalletCoordinator.InputOptions(source: .createWalletIntro))
        mobileCreateWalletCoordinator = coordinator
    }

    func closeCreateWalletSelector() {
        dismiss(with: .dismiss)
    }
}

// MARK: - MobileCreateWalletRoutable

extension CreateWalletSelectorCoordinator: MobileCreateWalletRoutable {
    func openOnboarding(options: OnboardingCoordinator.Options) {
        openOnboarding(inputOptions: options)
    }

    func closeMobileCreateWallet() {
        mobileCreateWalletCoordinator = nil
    }

    func openTos(url: URL) {
        safariManager.openURL(url)
    }
}

// MARK: - MobileCreateWalletDelegate

extension CreateWalletSelectorCoordinator: MobileCreateWalletDelegate {
    func onCreateWallet(userWalletModel: UserWalletModel) {
        openMain(userWalletModel: userWalletModel)
    }
}

// MARK: - Navigation

private extension CreateWalletSelectorCoordinator {
    func openOnboarding(inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.onboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        onboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension CreateWalletSelectorCoordinator {
    struct InputOptions {
        let showsBackButton: Bool

        init(showsBackButton: Bool = true) {
            self.showsBackButton = showsBackButton
        }
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case dismiss
    }
}
