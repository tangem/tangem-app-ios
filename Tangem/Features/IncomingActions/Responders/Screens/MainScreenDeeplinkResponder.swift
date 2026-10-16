//
//  MainScreenDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Opens on the main screen what the main screen can open itself, exactly as a tap would. Answers only while its
/// root is the top of what the user sees — otherwise the screen would go under whatever is open, so it is left to
/// whoever shows it over.
///
/// A destination without a case here needs no line here: it goes down the chain and is shown over the main screen.
final class MainScreenDeeplinkResponder {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    weak var coordinator: (any MainScreenDeeplinkRoutable)?

    /// The route still waiting for its data for the last link asked for. A newer link cancels it: what it was
    /// waiting for is dropped when it lands rather than opened over the newer screen.
    private var loadingTask: Task<Void, Never>?

    /// The main screen is up: it takes its place in the chain, and the link that waited for it at the door, if
    /// any, goes through the chain as a live one — the main screen itself answering first.
    func mainScreenDidAppear(delivering action: IncomingAction?) {
        incomingActionManager.becomeFirstResponder(self)

        if let action {
            incomingActionManager.deliver(action)
        }
    }
}

// MARK: - IncomingActionResponder

extension MainScreenDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        // Incoming actions are dispatched on the main thread, and so is everything a deeplink reads on its way
        // to a screen: wallet models, accounts, the coordinator.
        MainActor.assumeIsolated { open(action) }
    }
}

// MARK: - Native routes

@MainActor
private extension MainScreenDeeplinkResponder {
    func open(_ action: IncomingAction) -> Bool {
        guard case .navigation(let navigationAction) = action else {
            return false
        }

        // Whatever becomes of the newer link — opened here or shown over by someone else — the one still
        // waiting for its data is older than what the user asked for last.
        loadingTask?.cancel()
        loadingTask = nil

        guard let coordinator, canShow(navigationAction) else {
            return false
        }

        return open(navigationAction, using: coordinator)
    }

    func open(_ action: DeeplinkNavigationAction, using coordinator: any MainScreenDeeplinkRoutable) -> Bool {
        switch action {
        case .feed(let deeplink):
            prepare()
            coordinator.openFeed(selection: deeplink.makeSelection())

        case .token(let deeplink):
            // The token may still be on its way from the backend, so the link is claimed now and opened when it
            // lands — but only for a wallet this device has.
            guard !deeplink.isJointTransaction || FeatureProvider.isAvailable(.jointAccounts) else { return false }
            guard deeplink.findUserWalletModel() != nil else { return false }
            openTokenDetails(deeplink, action: action)

        case .staking(let deeplink):
            guard let options = deeplink.makeOptions() else { return false }
            prepare()
            coordinator.openStaking(options: options)

        case .yield(let deeplink):
            // A link that can't reach Yield mode lands on the Earn list, which is shown over the main screen
            // like any other list — so it is left to whoever does that.
            guard let target = deeplink.findTarget() else { return false }
            openYield(for: target, action: action)

        case .swap(let deeplink):
            guard let parameters = deeplink.makeParameters() else { return false }
            prepare()
            coordinator.openSwap(parameters: parameters)

        case .buy(let deeplink):
            guard let userWalletModel = deeplink.findUserWalletModel() else { return false }
            prepare()
            coordinator.openBuy(userWalletModel: userWalletModel)

        case .sell(let deeplink):
            guard let userWalletModel = deeplink.findUserWalletModel() else { return false }
            prepare()
            coordinator.openSell(userWalletModel: userWalletModel)

        case .tokenChart(let deeplink):
            prepare()
            coordinator.openMarketsTokenDetails(tokenModel: .deeplinkStub(tokenId: deeplink.tokenId))

        case .onboardVisa(let deeplink):
            return openTangemPayOnboarding(source: deeplink.onboardingSource, using: coordinator)

        case .payApp(let deeplink):
            return openTangemPayOnboarding(source: deeplink.onboardingSource, using: coordinator)

        case .tangemPayAccount(let deeplink):
            guard let userWalletModel = deeplink.findUserWalletModel() else { return false }
            openTangemPayAccount(of: userWalletModel, openingAction: deeplink.openingAction, action: .navigation(action))

        case .jointAccount(let deeplink):
            guard FeatureProvider.isAvailable(.jointAccounts), let userWalletModel = deeplink.findUserWalletModel() else { return false }
            openJointAccount(deeplink, of: userWalletModel, action: action)

        case .payCustomCard(let deeplink):
            // The stored key is what a campaign is owed on, and the welcome flow spends it before the main
            // screen is ever reached — a link arriving once nothing is owed any more asks for nothing.
            guard TangemPayCampaignService().pendingCampaignKey != nil else { return false }
            prepare()
            coordinator.openTangemPayCampaign(campaignKey: deeplink.campaignKey)

        // No native route: shown over the main screen, like from anywhere else.
        default:
            return false
        }

        return true
    }
}

// MARK: - Routes that have to wait for their data

@MainActor
private extension MainScreenDeeplinkResponder {
    func openTokenDetails(_ deeplink: TokenDeeplink, action: DeeplinkNavigationAction) {
        showWhenLoaded(.navigation(action)) {
            await deeplink.findTarget()
        } show: { target, coordinator in
            guard let target else {
                return Self.selectWallet(ofAccountNamedIn: deeplink, using: coordinator)
            }

            target.walletModel.startUpdateTask()
            coordinator.openTokenDetails(
                for: target.walletModel,
                userWalletModel: target.userWalletModel,
                pendingTransactionDetails: deeplink.pendingTransactionDetails
            )
            return true
        }
    }

    /// Yield mode, once the module state says which of its two screens the token opens.
    func openYield(for target: DeeplinkWalletModelLocator.Target, action: DeeplinkNavigationAction) {
        showWhenLoaded(.navigation(action)) {
            await YieldModuleDestinationResolver().resolve(
                walletModel: target.walletModel,
                userWalletModel: target.userWalletModel
            )
        } show: { destination, coordinator in
            switch destination {
            case .promo(let apy, let flowFactory):
                coordinator.openYieldModulePromoView(apy: apy, factory: flowFactory)
            case .active(let flowFactory):
                coordinator.openYieldModuleActiveInfo(factory: flowFactory)
            case nil:
                return false
            }

            return true
        }
    }

    /// The payment account, once its state says whether the wallet has one or still has to pick a plan.
    func openTangemPayAccount(of userWalletModel: any UserWalletModel, openingAction: TangemPayOpeningAction?, action: IncomingAction) {
        guard !RTCUtil.isRootedDevice,
              let accountModel = AccountModelsAggregator(.tangemPay).model(from: userWalletModel.accountModelsManager)
        else {
            return
        }

        showWhenLoaded(action) {
            try? await accountModel.statePublisher
                .filter { $0.tangemPayAccount != nil || $0.tariffPlanSelector != nil }
                .timeout(.seconds(Constants.tangemPayStateTimeout), scheduler: DispatchQueue.main)
                .receiveOnMain()
                .async()
        } show: { state, coordinator in
            if let tangemPayAccount = state?.tangemPayAccount {
                coordinator.openTangemPayMainView(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    tangemPayAccount: tangemPayAccount,
                    userWalletModel: userWalletModel,
                    openingAction: openingAction
                )
            } else if let tariffPlanSelector = state?.tariffPlanSelector {
                coordinator.openTangemPaySelectPlan(tariffPlanSelector: tariffPlanSelector, userWalletModel: userWalletModel)
            } else {
                return false
            }

            return true
        }
    }

    static func selectWallet(ofAccountNamedIn deeplink: TokenDeeplink, using coordinator: any MainScreenDeeplinkRoutable) -> Bool {
        guard deeplink.accountId != nil, let userWalletModel = deeplink.findUserWalletModel() else {
            return false
        }

        coordinator.selectWallet(userWalletId: userWalletModel.userWalletId)
        return true
    }

    func openJointAccount(_ deeplink: JointAccountDeeplink, of userWalletModel: any UserWalletModel, action: DeeplinkNavigationAction) {
        showWhenLoaded(.navigation(action)) {
            await deeplink.findJointAccount(in: userWalletModel)
        } show: { jointAccount, coordinator in
            coordinator.selectWallet(userWalletId: userWalletModel.userWalletId)

            guard let jointAccount else {
                return true
            }

            jointAccount.userTokensManager.sync {}

            switch deeplink.entry {
            case .members:
                coordinator.openJointAccountMembers(jointAccount: jointAccount, userWalletConfig: userWalletModel.config)
            case .overview:
                coordinator.expandAccount(jointAccount, userWalletId: userWalletModel.userWalletId)
            }

            return true
        }
    }

    func openTangemPayOnboarding(source: TangemPayOnboardingSource, using coordinator: any MainScreenDeeplinkRoutable) -> Bool {
        guard let availableSelection = tangemPayAvailabilityRepository.tangemPayOfferAvailability.availableWalletSelection else {
            return false
        }

        prepare()
        coordinator.openGetTangemPay(source: source, availableSelection: availableSelection)
        return true
    }

    /// Waits for what a route needs and hands it to the main screen only if the screen's root is still what
    /// the user sees — the wait is long enough for that to change, and then the link goes back to the chain
    /// for whoever shows it over, if anyone does. Unless a newer link has been asked for meanwhile: then the
    /// wait is cancelled and what it brings is dropped. The coordinator is held weakly on purpose: it owns
    /// this responder, so a strong capture would keep the whole main screen, and the wallet it was opened
    /// for, alive for as long as the wait lasts.
    func showWhenLoaded<Value>(
        _ action: IncomingAction,
        _ load: @escaping () async -> Value,
        show: @escaping (Value, any MainScreenDeeplinkRoutable) -> Bool
    ) {
        loadingTask = Task { @MainActor [weak self, weak coordinator] in
            let value = await load()

            guard let self, let coordinator, !Task.isCancelled else {
                return
            }

            guard canShow else {
                incomingActionManager.deliver(action)
                return
            }

            if show(value, coordinator) {
                prepare()
            }
        }
    }

    func prepare() {
        DeeplinkFloatingSheet.dismissActive()
    }
}

// MARK: - Readiness

@MainActor
private extension MainScreenDeeplinkResponder {
    func canShow(_ action: DeeplinkNavigationAction) -> Bool {
        switch action {
        case .feed: isRootOnTop
        default: canShow
        }
    }

    var canShow: Bool {
        isRootOnTop && !mainBottomSheetUIManager.isExpanded
    }

    var isRootOnTop: Bool {
        guard coordinator?.isRootVisible == true else {
            return false
        }

        return ScreenDeeplinkVisibility.isWindowRootOnTop()
    }
}

// MARK: - Constants

private extension MainScreenDeeplinkResponder {
    enum Constants {
        static let tangemPayStateTimeout: TimeInterval = 10
    }
}
