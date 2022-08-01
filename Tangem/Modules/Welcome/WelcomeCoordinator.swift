//
//  WelcomeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WelcomeCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var welcomeViewModel: WelcomeViewModel? = nil

    // MARK: - Child coordinators
    @Published var mainCoordinator: MainCoordinator? = nil
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var shopCoordinator: ShopCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil

    // MARK: - Child view models
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil

    // MARK: - Helpers
    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    // Fix ios13 navbar glitches
    @Published private(set) var navBarHidden: Bool = true

    // MARK: - Private
    private var welcomeLifecycleSubscription: AnyCancellable? = nil

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        let p1 = $mailViewModel.dropFirst().map { $0 == nil }
        let p2 = $disclaimerViewModel.dropFirst().map { $0 == nil }
        let p3 = $shopCoordinator.dropFirst().map { $0 == nil }
        let p4 = $modalOnboardingCoordinator.dropFirst().map { $0 == nil }
        let p5 = $tokenListCoordinator.dropFirst().map { $0 == nil }
        let p6 = $mailViewModel.dropFirst().map { $0 == nil }
        let p7 = $disclaimerViewModel.dropFirst().map { $0 == nil }

        return p1.merge(with: p2, p3, p4, p5, p6, p7)
            .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WelcomeCoordinator.Options) {
        welcomeViewModel = .init(coordinator: self)
        subscribeToWelcomeLifecycle()

        if options.shouldScan {
            welcomeViewModel?.scanCard()
        }
    }

    private func subscribeToWelcomeLifecycle() {
        welcomeLifecycleSubscription = lifecyclePublisher
            .sink { [unowned self] viewDismissed in
                if viewDismissed {
                    self.welcomeViewModel?.becomeActive()
                } else {
                    self.welcomeViewModel?.resignActve()
                }
            }
    }
}

extension WelcomeCoordinator {
    struct Options {
        let shouldScan: Bool
    }
}

extension WelcomeCoordinator: WelcomeRoutable {
    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openOnboarding(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            if let card = input.cardInput.cardModel {
                self?.openMain(with: card)
            }
        }

        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] _ in
            self?.pushedOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
    }

    func openMain(with cardModel: CardViewModel) {
        navBarHidden = false
        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.navBarHidden = true
            self?.mainCoordinator = nil

            if options.newScan {
                self?.welcomeViewModel?.scanCard()
            }
        }

        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        mainCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, recipient: recipient, emailType: .failedToScanCard)
    }

    func openDisclaimer() {
        disclaimerViewModel = DisclaimerViewModel(style: .sheet, showAccept: true, coordinator: self)
    }

    func openTokensList() {
        let dismissAction: Action = { [weak self] in
            self?.tokenListCoordinator = nil
        }
        let coordinator = TokenListCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .show)
        self.tokenListCoordinator = coordinator
    }

    func openShop() {
        let coordinator = ShopCoordinator()
        coordinator.start()
        self.shopCoordinator = coordinator
    }
}

extension WelcomeCoordinator: DisclaimerRoutable {
    func dismissAcceptedDisclaimer() {
        self.disclaimerViewModel = nil
        self.welcomeViewModel?.scanCard()
    }
}
