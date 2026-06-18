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
    @Injected(\.mobileWalletPromoService) private var mobileWalletPromoService: MobileWalletPromoService

    private var mailPresenterLifecycleSubject = PassthroughSubject<Bool, Never>()

    // MARK: - Root view model

    @Published var rootViewModel: WelcomeViewModel?

    // MARK: - Child coordinators

    @Published var welcomeOnboardingCoordinator: WelcomeOnboardingCoordinator? = nil
    @Published var createWalletSelectorCoordinator: CreateWalletSelectorCoordinator? = nil
    @Published var tangemPayMobileOnboardingCoordinator: TangemPayMobileOnboardingCoordinator? = nil

    // MARK: - Child view models

    @Published var searchTokensViewModel: WelcomeSearchTokensViewModel? = nil

    // MARK: - Private

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        // Only modals, because the modal presentation will not trigger onAppear/onDisappear events
        var publishers: [AnyPublisher<Bool, Never>] = []
        publishers.append($searchTokensViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($welcomeOnboardingCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($tangemPayMobileOnboardingCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append(mailPresenterLifecycleSubject.eraseToAnyPublisher())

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    private var tangemPayMobileOnboardingObserver: AnyCancellable?
    private var needsToShowTangemPayMobileOnboarding = false

    /// When the user carries a referral signal, the intro stories are skipped in favour of the
    /// alternative wallet creation screen. We can't open it until any startup onboarding is dismissed.
    private var shouldSkipStories = false

    required init(dismissAction: @escaping Action<OutputOptions>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("WelcomeCoordinator deinit")
    }

    func start(with options: WelcomeCoordinator.Options) {
        shouldSkipStories = FeatureProvider.isAvailable(.hideStoriesInMobileWallet)
            && mobileWalletPromoService.shouldShowMobilePromoWalletSelector

        if !shouldSkipStories {
            let storiesModel = StoriesViewModel()
            let welcomeViewModel = WelcomeViewModel(coordinator: self, storiesModel: storiesModel)
            storiesModel.setDelegate(delegate: welcomeViewModel)
            storiesModel.setLifecyclePublisher(publisher: lifecyclePublisher)
            rootViewModel = welcomeViewModel
        }

        if let onboarding = WelcomeOnboardingsHelper().getStartupOnboarding() {
            switch onboarding {
            case .welcome(let steps):
                showWelcomeOnboarding(steps: steps)
            case .tangemPayMobile:
                showTangemPayMobileOnboarding()
            }
        } else if shouldSkipStories {
            openCreateWallet(showsBackButton: false)
        }

        bindTangemPayMobileOnboarding()
    }

    private func bindTangemPayMobileOnboarding() {
        tangemPayMobileOnboardingObserver = AppSettings.shared.$needsTangemPayMobileOnboarding
            .dropFirst()
            .first()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { coordinator, isOnboardingNeeded in
                guard coordinator.tangemPayMobileOnboardingCoordinator == nil, isOnboardingNeeded else {
                    return
                }

                // If the notification-permission (welcome) onboarding is still on screen,
                // defer Tangem Pay onboarding until the user dismisses it, so the screens
                // are shown sequentially instead of racing.
                if coordinator.welcomeOnboardingCoordinator != nil {
                    coordinator.needsToShowTangemPayMobileOnboarding = true
                } else {
                    coordinator.showTangemPayMobileOnboarding()
                }
            }
    }

    private func showWelcomeOnboarding(steps: [WelcomeOnboardingStep]) {
        let factory = PushNotificationsHelpersFactory()
        let permissionManager = factory.makePermissionManagerForWelcomeOnboarding(using: pushNotificationsInteractor)

        let dismissAction: Action<WelcomeOnboardingCoordinator.OutputOptions> = { [weak self] _ in
            guard let self else { return }

            withAnimation(.easeIn) {
                self.welcomeOnboardingCoordinator = nil
            }

            if needsToShowTangemPayMobileOnboarding {
                needsToShowTangemPayMobileOnboarding = false
                showTangemPayMobileOnboarding()
            } else if shouldSkipStories, createWalletSelectorCoordinator == nil {
                openCreateWallet(showsBackButton: false)
            }
        }

        let coordinator = WelcomeOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(steps: steps, pushNotificationsPermissionManager: permissionManager))
        welcomeOnboardingCoordinator = coordinator
    }

    private func showTangemPayMobileOnboarding() {
        let dismissAction: Action<TangemPayMobileOnboardingCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }
            switch options {
            case .main(let userWalletModel):
                dismiss(with: .main(userWalletModel))
            }
        }

        let coordinator = TangemPayMobileOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: ())
        tangemPayMobileOnboardingCoordinator = coordinator
    }

    private func openCreateWallet(showsBackButton: Bool) {
        let dismissAction: Action<CreateWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let model):
                self?.openMain(with: model)
            case .dismiss:
                self?.createWalletSelectorCoordinator = nil
            }
        }

        let coordinator = CreateWalletSelectorCoordinator(dismissAction: dismissAction)
        let inputOptions = CreateWalletSelectorCoordinator.InputOptions(showsBackButton: showsBackButton)
        coordinator.start(with: inputOptions)
        createWalletSelectorCoordinator = coordinator
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
        openCreateWallet(showsBackButton: true)
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
