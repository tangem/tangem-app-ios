//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class SingleWalletMainContentViewModel: SingleTokenBaseViewModel, ObservableObject {
    // MARK: - ViewState

    @Published var notificationInputs: [NotificationViewInput] = []

    // MARK: - Dependencies

    private let userWalletNotificationManager: NotificationManager
    private unowned let singleWalletCoordinator: SingleWalletMainContentRoutable

    private var updateSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        userTokensManager: UserTokensManager,
        exchangeUtility: ExchangeCryptoUtility,
        userWalletNotificationManager: NotificationManager,
        tokenNotificationManager: NotificationManager,
        coordinator: SingleWalletMainContentRoutable
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        singleWalletCoordinator = coordinator

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            userTokensManager: userTokensManager,
            exchangeUtility: exchangeUtility,
            notificationManager: tokenNotificationManager,
            coordinator: coordinator
        )

        bind()
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateSubscription == nil else {
            return
        }

        isReloadingTransactionHistory = true
        updateSubscription = walletModel.generalUpdate(silent: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.isReloadingTransactionHistory = false
                completionHandler()
                self?.updateSubscription = nil
            })
    }

    private func bind() {
        userWalletNotificationManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
