//
//  CardSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CardSettingsCoordinator: CoordinatorObject, ManageTokensBottomSheetIntermediateDisplayable {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var cardSettingsViewModel: CardSettingsViewModel?

    // MARK: - Child view models

    @Published var resetToFactoryViewModel: ResetToFactoryViewModel?

    // MARK: - Child coordinators

    @Published var securityManagementCoordinator: SecurityModeCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var accessCodeRecoverySettingsViewModel: AccessCodeRecoverySettingsViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    // MARK: - Delegates

    weak var nextManageTokensBottomSheetDisplayable: ManageTokensBottomSheetDisplayable?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        cardSettingsViewModel = CardSettingsViewModel(
            cardModel: options.cardModel,
            coordinator: self
        )
    }
}

// MARK: - Options

extension CardSettingsCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

// MARK: - CardSettingsRoutable

extension CardSettingsCoordinator: CardSettingsRoutable {
    func openOnboarding(with input: OnboardingInput, hasOtherCards: Bool) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.modalOnboardingCoordinator = nil
        }

        let popToMainAction: Action<PopToRootOptions> = { [weak self] _ in
            self?.modalOnboardingCoordinator = nil
            self?.dismiss()
        }

        let coordinator = OnboardingCoordinator(
            dismissAction: dismissAction,
            popToRootAction: hasOtherCards ? popToMainAction : popToRootAction
        )
        coordinator.nextManageTokensBottomSheetDisplayable = self
        let options = OnboardingCoordinator.Options(input: input, destination: .root)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openSecurityMode(cardModel: CardViewModel) {
        let coordinator = SecurityModeCoordinator(popToRootAction: popToRootAction)
        let options = SecurityModeCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        securityManagementCoordinator = coordinator
    }

    func openResetCardToFactoryWarning(with input: ResetToFactoryViewModel.Input) {
        Analytics.log(.buttonFactoryReset)
        resetToFactoryViewModel = ResetToFactoryViewModel(
            input: input,
            coordinator: self
        )
    }

    func openAccessCodeRecoverySettings(using provider: AccessCodeRecoverySettingsProvider) {
        accessCodeRecoverySettingsViewModel = .init(settingsProvider: provider)
    }
}

// MARK: - ResetToFactoryViewRoutable

extension CardSettingsCoordinator: ResetToFactoryViewRoutable {
    func didResetCard() {
        cardSettingsViewModel?.didResetCard()
    }
}
