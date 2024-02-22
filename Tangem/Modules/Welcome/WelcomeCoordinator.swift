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
    enum ViewState: Equatable {
        case welcome(WelcomeViewModel)
        case main(MainCoordinator)

        var isMain: Bool {
            if case .main = self {
                return true
            }
            return false
        }

        static func == (lhs: WelcomeCoordinator.ViewState, rhs: WelcomeCoordinator.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.welcome, .welcome), (.main, .main):
                return true
            default:
                return false
            }
        }
    }

    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Main view model

    @Published private(set) var viewState: ViewState? = nil
    private var welcomeViewModel: WelcomeViewModel? {
        if case .welcome(let viewModel) = viewState {
            return viewModel
        }
        return nil
    }

    // MARK: - Child coordinators

    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var legacyTokenListCoordinator: LegacyTokenListCoordinator? = nil
    @Published var promotionCoordinator: PromotionCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil

    // MARK: - Private

    private var welcomeLifecycleSubscription: AnyCancellable?

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        // Only modals, because the modal presentation will not trigger onAppear/onDissapear events
        var publishers: [AnyPublisher<Bool, Never>] = []
        publishers.append($mailViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($legacyTokenListCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($promotionCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WelcomeCoordinator.Options) {
        viewState = .welcome(WelcomeViewModel(shouldScanOnAppear: options.shouldScan, coordinator: self))
        subscribeToWelcomeLifecycle()
        print("Welcome coordinator viewState started \(viewState)")
    }

    private func subscribeToWelcomeLifecycle() {
        welcomeLifecycleSubscription = lifecyclePublisher
            .sink { [weak self] viewDismissed in
                guard let self else { return }

                if viewDismissed {
                    welcomeViewModel?.becomeActive()
                } else {
                    welcomeViewModel?.resignActve()
                }
            }
    }
}

// MARK: - Options

extension WelcomeCoordinator {
    struct Options {
        let shouldScan: Bool
    }
}

// MARK: - WelcomeRoutable

extension WelcomeCoordinator: WelcomeRoutable {
    func openOnboarding(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.pushedOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .main)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
    }

    func openMain(with cardModel: CardViewModel) {
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(userWalletModel: cardModel)
        coordinator.start(with: options)
        viewState = .main(coordinator)
        print("Welcome coordinator viewState changed to \(viewState)")
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }

    func openPromotion() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.promotionCoordinator = nil
        }

        let coordinator = PromotionCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .newUser)
        promotionCoordinator = coordinator
    }

    func openTokensList() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.legacyTokenListCoordinator = nil
        }

        let coordinator = LegacyTokenListCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .show)
        legacyTokenListCoordinator = coordinator
    }

    func openShop() {
        Analytics.log(.shopScreenOpened)
        safariManager.openURL(AppConstants.webShopUrl)
    }
}
