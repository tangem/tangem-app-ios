//
//  WelcomeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemSdk

final class WelcomeCoordinator: CoordinatorObject {
    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var mailPresenterLifecycleSubject = PassthroughSubject<Bool, Never>()

    // MARK: - Root view model

    @Published var rootViewModel: WelcomeViewModel?

    // MARK: - Child coordinators

    @Published var promotionCoordinator: PromotionCoordinator? = nil
    @Published var welcomeOnboardingCoordinator: WelcomeOnboardingCoordinator? = nil
    @Published var createWalletSelectorCoordinator: CreateWalletSelectorCoordinator? = nil

    // MARK: - Child view models

    @Published var searchTokensViewModel: WelcomeSearchTokensViewModel? = nil

    // MARK: - Private

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        // Only modals, because the modal presentation will not trigger onAppear/onDisappear events
        var publishers: [AnyPublisher<Bool, Never>] = []
        publishers.append($searchTokensViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($promotionCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($welcomeOnboardingCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append(mailPresenterLifecycleSubject.eraseToAnyPublisher())

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action<OutputOptions>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug(self)
    }

    func start(with options: WelcomeCoordinator.Options) {
        let storiesModel = StoriesViewModel()
        let welcomeViewModel = WelcomeViewModel(coordinator: self, storiesModel: storiesModel)
        storiesModel.setDelegate(delegate: welcomeViewModel)
        storiesModel.setLifecyclePublisher(publisher: lifecyclePublisher)
        rootViewModel = welcomeViewModel
        showWelcomeOnboardingIfNeeded()
    }

    private func showWelcomeOnboardingIfNeeded() {
        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWelcomeOnboarding(using: pushNotificationsInteractor)
        let permissionManager = factory.makePermissionManagerForWelcomeOnboarding(using: pushNotificationsInteractor)
        let builder = WelcomeOnboardingStepsBuilder(isPushNotificationsAvailable: availabilityProvider.isAvailable)
        let steps = builder.buildSteps()
        guard !steps.isEmpty else {
            return
        }

        let dismissAction: Action<WelcomeOnboardingCoordinator.OutputOptions> = { [weak self] _ in
            withAnimation(.easeIn) {
                self?.welcomeOnboardingCoordinator = nil
            }
        }

        let coordinator = WelcomeOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(steps: steps, pushNotificationsPermissionManager: permissionManager))
        welcomeOnboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension WelcomeCoordinator {
    struct Options {}

    enum OutputOptions {
        case main(UserWalletModel)
        case onboarding(OnboardingInput)
    }
}

// MARK: - WelcomeRoutable

extension WelcomeCoordinator: WelcomeRoutable {
    func openOnboarding(with input: OnboardingInput) {
        dismiss(with: .onboarding(input))
    }

    func openCreateWallet() {
        let dismissAction: Action<CreateWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let model):
                self?.openMain(with: model)
            case .dismiss:
                self?.createWalletSelectorCoordinator = nil
            }
        }

        let coordinator = CreateWalletSelectorCoordinator(dismissAction: dismissAction)
        let inputOptions = CreateWalletSelectorCoordinator.InputOptions()
        coordinator.start(with: inputOptions)
        createWalletSelectorCoordinator = coordinator
    }

    func openMain(with userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel))
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)

        Task { @MainActor in
            let mailPresenterBeingDismissed = true
            mailPresenterLifecycleSubject.send(!mailPresenterBeingDismissed)

            mailPresenter.present(
                viewModel: mailViewModel,
                completion: { [weak self] in
                    self?.mailPresenterLifecycleSubject.send(mailPresenterBeingDismissed)
                }
            )
        }
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
        searchTokensViewModel = .init()
    }

    func openShop() {
        Analytics.log(.shopScreenOpened)
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .prospect))
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}
