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
    private var hasPositiveBalanceSubject = PassthroughSubject<Bool, Never>()
    private var isMainAppearedSubject = CurrentValueSubject<Bool?, Never>(nil)
    private var hasMainDeepLinkSubject = CurrentValueSubject<Bool?, Never>(nil)

    private var isActivationNeeded: Bool = true
    private var isSubscriptionNeeded: Bool = true

    private let waitingBalanceInterval: TimeInterval = 0.5
    private let waitingDeepLinkInterval: TimeInterval = 0.5

    private var observation: Observation?
    private var activationSubscription: AnyCancellable?

    fileprivate init() {}

    func observe(userWalletModel: UserWalletModel, onActivation: @escaping (UserWalletModel) -> Void) {
        guard observation == nil else { return }

        observation = Observation(
            userWalletModel: userWalletModel,
            activation: onActivation
        )

        let config = userWalletModel.config
        let needBackup = config.hasFeature(.mnemonicBackup) && config.hasFeature(.iCloudBackup)
        let needAccessCode = config.hasFeature(.userWalletAccessCode) && config.userWalletAccessCodeStatus == .none

        if !needBackup, !needAccessCode {
            isActivationNeeded = false
        }
    }

    func onMain(userWalletId: UserWalletId, isAppeared: Bool) {
        guard
            isActivationNeeded,
            let observation,
            observation.userWalletModel.userWalletId == userWalletId
        else {
            return
        }

        if isSubscriptionNeeded {
            bind(observation: observation)
        }

        isMainAppearedSubject.send(isAppeared)
    }

    func onIncoming(action: IncomingAction) {
        guard case .navigation(let deepLinkAction) = action else {
            return
        }

        let hasMainDeepLink = switch deepLinkAction.destination {
        case .markets, .buy, .sell, .swap, .referral: true
        default: false
        }

        hasMainDeepLinkSubject.send(hasMainDeepLink)
    }

    private func bind(observation: Observation) {
        isSubscriptionNeeded = false

        let hasPositiveBalanceTimer: AnyPublisher<Bool, Never> = Just(false)
            .delay(for: .seconds(waitingBalanceInterval), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        let hasPositiveBalancePublisher = AccountsFeatureAwareWalletModelsResolver
            .walletModelsPublisher(for: observation.userWalletModel)
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
                self?.handle(
                    observation: observation,
                    hasPositiveBalance: hasPositiveBalance,
                    isMainAppeared: isMainAppeared,
                    hasMainDeepLink: hasMainDeepLink
                )
            }
    }

    private func handle(
        observation: Observation,
        hasPositiveBalance: Bool,
        isMainAppeared: Bool,
        hasMainDeepLink: Bool
    ) {
        guard isActivationNeeded else { return }
        isActivationNeeded = false

        if isMainAppeared, hasPositiveBalance, !hasMainDeepLink {
            observation.activation(observation.userWalletModel)
        }
    }
}

// MARK: - Types

private extension MobileFinishActivationManager {
    struct Observation {
        let userWalletModel: UserWalletModel
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
