//
//  WelcomeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

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

    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService

    // MARK: - Private
    private var welcomeLifecycleSubscription: AnyCancellable? = nil

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        // Only modals, because the modal presentation will not trigger onAppear/onDissapear events
        var publishers: [AnyPublisher<Bool, Never>] = []
        publishers.append($mailViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($shopCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($modalOnboardingCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($tokenListCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($disclaimerViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WelcomeCoordinator.Options) {
        let welcomeViewModel = WelcomeViewModel(coordinator: self)
        self.welcomeViewModel = welcomeViewModel
        subscribeToWelcomeLifecycle()

        if options.shouldScan {
            welcomeViewModel.scanCard()
        } else if welcomeViewModel.shouldShowAuthenticationView {
            welcomeViewModel.tryBiometricAuthentication()
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
        let options = OnboardingCoordinator.Options(input: input, shouldOpenMainOnFinish: false)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openOnboarding(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.pushedOnboardingCoordinator = nil
        }

        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.pushedOnboardingCoordinator = nil

            if options.newScan {
                self?.welcomeViewModel?.scanCard()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, shouldOpenMainOnFinish: true)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
    }

    func openMain(with cardModel: CardViewModel) {
        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.mainCoordinator = nil

            if options.newScan {
                self?.welcomeViewModel?.scanCard()
            }
        }

        Analytics.log(.mainPageEnter)
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
