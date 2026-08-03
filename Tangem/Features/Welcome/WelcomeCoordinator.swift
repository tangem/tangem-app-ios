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

    @Published var welcomeOnboardingCoordinator: WelcomeOnboardingCoordinator? = nil
    @Published var createWalletSelectorCoordinator: CreateWalletSelectorCoordinator? = nil
    @Published var tangemPayMobileOnboardingCoordinator: TangemPayMobileOnboardingCoordinator? = nil

    // MARK: - Child view models

    @Published var searchTokensViewModel: WelcomeSearchTokensViewModel? = nil

    // MARK: - Private

    private lazy var processor = WelcomeProcessor(isIdle: isIdlePublisher)
    private var bag: Set<AnyCancellable> = []

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

    /// `true` while nothing the user navigated to themselves is on screen — create wallet, token search or
    /// mail. The processor gates the promo/Tangem Pay deep links on this, so they never present over such a
    /// screen (it's `true` when all three are closed). Startup onboardings aren't here — they live in `State`
    /// and are sequenced by the reducer.
    private var isIdlePublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(
            $createWalletSelectorCoordinator.map { $0 == nil },
            $searchTokensViewModel.map { $0 == nil },
            mailPresenterLifecycleSubject.prepend(true)
        )
        .map { createWalletClosed, searchClosed, mailClosed in
            createWalletClosed && searchClosed && mailClosed
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action<OutputOptions>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("WelcomeCoordinator deinit")
    }

    func start(with options: WelcomeCoordinator.Options) {
        bind()
    }

    private func bind() {
        // Touching `processor` builds it and computes the real state, so the first emission is never a placeholder.
        processor.statePublisher
            .withWeakCaptureOf(self)
            .sink { coordinator, state in
                coordinator.render(state)
            }
            .store(in: &bag)
    }

    // MARK: - Rendering

    private func render(_ state: WelcomeProcessor.State) {
        // The welcome onboarding gates the deep link — while it's up, nothing else shows over it. It also
        // needs the stories as its backdrop (its material background blurs them), so keep the base layer
        // until it's dismissed, even once a promo deep link has resolved underneath it.
        if let steps = state.welcomeOnboarding {
            setStoriesVisible(true)
            showWelcomeOnboarding(steps: steps)
            return
        }

        // Stories are the base layer, dropped only for the promo flow.
        setStoriesVisible(state.deepLink != .promo)

        switch state.deepLink {
        case .tangemPay:
            showTangemPayMobileOnboarding()
        case .promo:
            openCreateWallet(showsBackButton: false)
        case .none:
            break
        }
    }

    private func setStoriesVisible(_ visible: Bool) {
        if visible {
            if rootViewModel == nil {
                rootViewModel = makeStoriesViewModel()
            }
        } else if rootViewModel != nil {
            rootViewModel = nil
        }
    }

    private func makeStoriesViewModel() -> WelcomeViewModel {
        let storiesModel = StoriesViewModel()
        let welcomeViewModel = WelcomeViewModel(coordinator: self, storiesModel: storiesModel)
        storiesModel.setDelegate(delegate: welcomeViewModel)
        storiesModel.setLifecyclePublisher(publisher: lifecyclePublisher)
        return welcomeViewModel
    }

    private func showWelcomeOnboarding(steps: [WelcomeOnboardingStep]) {
        guard welcomeOnboardingCoordinator == nil else { return }

        let factory = PushNotificationsHelpersFactory()
        let permissionManager = factory.makePermissionManagerForWelcomeOnboarding(using: pushNotificationsInteractor)

        let dismissAction: Action<WelcomeOnboardingCoordinator.OutputOptions> = { [weak self] _ in
            guard let self else { return }

            withAnimation(.easeIn) {
                self.welcomeOnboardingCoordinator = nil
            }

            processor.welcomeOnboardingDismissed()
        }

        let coordinator = WelcomeOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(steps: steps, pushNotificationsPermissionManager: permissionManager))
        welcomeOnboardingCoordinator = coordinator
    }

    private func showTangemPayMobileOnboarding() {
        guard tangemPayMobileOnboardingCoordinator == nil else { return }

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
        guard createWalletSelectorCoordinator == nil else { return }

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
