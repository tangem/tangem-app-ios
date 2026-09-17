//
//  MobileFinishActivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MobileFinishActivationManager {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var hasPositiveBalanceSubject = PassthroughSubject<Bool, Never>()
    private var isMainAppearedSubject = CurrentValueSubject<Bool?, Never>(nil)
    private var hasMainDeepLinkSubject = CurrentValueSubject<Bool?, Never>(nil)

    private var isActivationNeeded: Bool = true
    private var isSubscriptionNeeded: Bool = true

    private let waitingBalanceInterval: TimeInterval = 0.5
    private let waitingDeepLinkInterval: TimeInterval = 0.5

    private var observation: Observation?
    private var activationSubscription: AnyCancellable?
    private var incomingActionsSubscription: AnyCancellable?

    fileprivate init() {}

    /// Listens for the deeplinks that take the user into a flow on the main screen, so the activation sheet
    /// doesn't cut in on one. Started at launch: a link the app was opened by arrives before the main screen.
    func initialize() {
        incomingActionsSubscription = incomingActionManager.incomingActionsPublisher
            .withWeakCaptureOf(self)
            .sink { manager, action in
                manager.onIncoming(action: action)
            }
    }

    func observeUserWallet(
        id userWalletId: UserWalletId,
        config userWalletConfig: UserWalletConfig,
        onActivation: @escaping (UserWalletModel) -> Void
    ) {
        guard isActivationNeeded else { return }
        observation = Observation(userWalletId: userWalletId, activation: onActivation)

        let needBackup = MobileBackupStatusUtil.isBackupNeeded(config: userWalletConfig)
        let needAccessCode = userWalletConfig.hasFeature(.userWalletAccessCode) && userWalletConfig.userWalletAccessCodeStatus == .none

        if !needBackup, !needAccessCode {
            isActivationNeeded = false
        }
    }

    func onMain(userWalletModel: UserWalletModel, isAppeared: Bool) {
        guard
            isActivationNeeded,
            observation?.userWalletId == userWalletModel.userWalletId
        else {
            return
        }

        if isSubscriptionNeeded {
            let walletModelsPublisher = AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager)
            bind(with: walletModelsPublisher)
        }

        isMainAppearedSubject.send(isAppeared)
    }

    private func onIncoming(action: IncomingAction) {
        switch action {
        case .navigation(let deepLinkAction):
            let hasMainDeepLink = switch deepLinkAction {
            case .markets, .buy, .sell, .swap, .referral: true
            default: false
            }

            hasMainDeepLinkSubject.send(hasMainDeepLink)

        case .externalLink:
            hasMainDeepLinkSubject.send(false)

        case .walletConnect, .start, .dismissSafari:
            break
        }
    }

    private func bind(with walletModelsPublisher: AnyPublisher<[any WalletModel], Never>) {
        isSubscriptionNeeded = false

        let hasPositiveBalanceTimer: AnyPublisher<Bool, Never> = Just(false)
            .delay(for: .seconds(waitingBalanceInterval), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        let hasPositiveBalancePublisher = walletModelsPublisher
            .map { walletModels in
                let totalBalances = walletModels.compactMap(\.availableBalanceProvider.balanceType.value)
                return totalBalances.contains { $0 > 0 }
            }
            .merge(with: hasPositiveBalanceTimer)
            .first()

        let hasMainDeepLinkTimer: AnyPublisher<Bool, Never> = Just(false)
            .delay(for: .seconds(waitingDeepLinkInterval), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        let hasMainDeepLinkPublisher = hasMainDeepLinkSubject
            .compactMap { $0 }
            .merge(with: hasMainDeepLinkTimer)
            .first()

        let isMainAppearedPublisher = isMainAppearedSubject.compactMap { $0 }

        activationSubscription = hasPositiveBalancePublisher
            .combineLatest(isMainAppearedPublisher, hasMainDeepLinkPublisher)
            .sink { [weak self] hasPositiveBalance, isMainAppeared, hasMainDeepLink in
                self?.activateIfNeeded(
                    hasPositiveBalance: hasPositiveBalance,
                    isMainAppeared: isMainAppeared,
                    hasMainDeepLink: hasMainDeepLink
                )
            }
    }

    private func activateIfNeeded(
        hasPositiveBalance: Bool,
        isMainAppeared: Bool,
        hasMainDeepLink: Bool
    ) {
        guard isActivationNeeded else { return }

        isActivationNeeded = false
        activationSubscription = nil

        guard
            let observation,
            let userWalletModel = userWalletRepository.models[observation.userWalletId]
        else {
            return
        }

        if isMainAppeared, hasPositiveBalance, !hasMainDeepLink {
            observation.activation(userWalletModel)
        }
    }
}

// MARK: - Types

private extension MobileFinishActivationManager {
    struct Observation {
        let userWalletId: UserWalletId
        let activation: (UserWalletModel) -> Void
    }
}

// MARK: - Injections

private struct MobileFinishActivationManagerKey: InjectionKey {
    static var currentValue = MobileFinishActivationManager()
}

extension InjectedValues {
    var mobileFinishActivationManager: MobileFinishActivationManager {
        get { Self[MobileFinishActivationManagerKey.self] }
        set { Self[MobileFinishActivationManagerKey.self] = newValue }
    }
}
