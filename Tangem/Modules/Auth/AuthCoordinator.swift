//
//  AuthCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AuthCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model
    @Published private(set) var rootViewModel: AuthViewModel?

    // MARK: - Child coordinators
    @Published var mainCoordinator: MainCoordinator?
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Child view models
    @Published var mailViewModel: MailViewModel?
    @Published var disclaimerViewModel: DisclaimerViewModel?

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        self.rootViewModel = .init(unlockOnStart: options.unlockOnStart, coordinator: self)
    }
}

// MARK: - Options

extension AuthCoordinator {
    struct Options {
        let unlockOnStart: Bool

        static let `default` = Options(unlockOnStart: false)
    }
}

// MARK: - AuthRoutable

extension AuthCoordinator: AuthRoutable {
    func openOnboarding(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.pushedOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .main)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
    }

    func openMain(with cardModel: CardViewModel) {
        Analytics.log(.screenOpened)
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        mainCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, recipient: recipient, emailType: .failedToScanCard)
    }

    func openDisclaimer(at url: URL, _ handler: @escaping (Bool) -> Void) {
        disclaimerViewModel = DisclaimerViewModel(url: url, style: .sheet, coordinator: self, acceptanceHandler: handler)
    }
}

extension AuthCoordinator: DisclaimerRoutable {
    func dismissDisclaimer() {
        self.disclaimerViewModel = nil
    }
}
