//
//  UserWalletListCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletListCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UserWalletListViewModel?

    // MARK: - Child coordinators

    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil

    private weak var output: UserWalletListCoordinatorOutput?

    required init(
        output: UserWalletListCoordinatorOutput,
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.output = output
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension UserWalletListCoordinator {
    enum Options {
        case `default`
    }
}

extension UserWalletListCoordinator: UserWalletListRoutable {
    func openDisclaimer(at url: URL, _ handler: @escaping (Bool) -> Void) {
        disclaimerViewModel = DisclaimerViewModel(url: url, style: .sheet, coordinator: self, acceptanceHandler: handler)
    }

    func openOnboarding(with input: OnboardingInput) {
        output?.dismissAndOpenOnboarding(with: input)
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, recipient: recipient, emailType: emailType)
    }
}

extension UserWalletListCoordinator: DisclaimerRoutable {
    func dismissDisclaimer() {
        disclaimerViewModel = nil
    }
}
