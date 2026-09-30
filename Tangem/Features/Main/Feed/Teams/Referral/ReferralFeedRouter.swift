//
//  ReferralFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol ReferralFeedRoutable: AnyObject {
    func openReferral(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        resolveAvailableWallet: @escaping (UserWalletId) -> UserWalletModel?,
        onDismiss: @escaping (UserWalletId) -> Void
    )
}

struct FeedReferralWalletCandidate: Equatable {
    enum State: Equatable {
        case available(reward: String)
        case unavailable
        case loading
        case failure
    }

    let wallet: UserWalletModel
    let state: State

    var reward: String? {
        guard case .available(let reward) = state else { return nil }
        return reward
    }

    var isAvailable: Bool { reward != nil }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wallet === rhs.wallet && lhs.state == rhs.state
    }
}

final class ReferralFeedRouter: ReferralFeedRoutable {
    private weak var navigation: (any FeedNavigation)?
    private let widgetSheetPresenter: FeedWidgetSheetPresenter
    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext, widgetSheetPresenter: FeedWidgetSheetPresenter) {
        navigation = context.navigation
        self.widgetSheetPresenter = widgetSheetPresenter
        popToRootAction = context.popToRootAction
    }

    func openReferral(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        resolveAvailableWallet: @escaping (UserWalletId) -> UserWalletModel?,
        onDismiss: @escaping (UserWalletId) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self, let navigation, navigation.presented == nil, !widgetSheetPresenter.isPresenting else { return }

            let availableCandidates = candidates.filter(\.isAvailable)
            guard let candidate = availableCandidates.first else { return }

            guard availableCandidates.count > 1 else {
                openReferral(for: candidate.wallet.userWalletId, resolveAvailableWallet: resolveAvailableWallet, onDismiss: onDismiss)
                return
            }

            let selector = FeedReferralWalletSelectorViewModel(
                candidates: candidates,
                candidatesPublisher: candidatesPublisher,
                onSelect: { [weak self] walletId in
                    Task { @MainActor [weak self] in
                        self?.openReferral(for: walletId, resolveAvailableWallet: resolveAvailableWallet, onDismiss: onDismiss)
                    }
                },
                close: { [weak self] in self?.widgetSheetPresenter.dismiss() }
            )
            widgetSheetPresenter.enqueue(selector)
        }
    }
}

@MainActor
private extension ReferralFeedRouter {
    func openReferral(
        for walletId: UserWalletId,
        resolveAvailableWallet: (UserWalletId) -> UserWalletModel?,
        onDismiss: @escaping (UserWalletId) -> Void
    ) {
        guard let navigation, navigation.presented == nil, let wallet = resolveAvailableWallet(walletId) else { return }

        if widgetSheetPresenter.isPresenting {
            widgetSheetPresenter.dismiss()
        }

        let coordinator = ReferralCoordinator(
            dismissAction: { [weak self] _ in
                guard let navigation = self?.navigation, case .referral = navigation.presented else { return }

                navigation.dismissPresented()
                onDismiss(wallet.userWalletId)
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(input: .init(
            userWalletId: wallet.userWalletId.value,
            supportedBlockchains: wallet.config.supportedBlockchains,
            accountModelsManager: wallet.accountModelsManager,
            tokenIconInfoBuilder: TokenIconInfoBuilder(),
            userWalletModel: wallet
        )))
        navigation.present(.referral(coordinator))
    }
}
