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

    private var updateSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    private weak var mainViewDelegate: MainViewDelegate?

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        userWalletNotificationManager: NotificationManager,
        tokenNotificationManager: NotificationManager,
        mainViewDelegate: MainViewDelegate?,
        tokenRouter: SingleTokenRoutable
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        self.mainViewDelegate = mainViewDelegate

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: tokenNotificationManager,
            tokenRouter: tokenRouter
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

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        mainViewDelegate?.present(actionSheet: actionSheet)
    }

    private func bind() {
        userWalletNotificationManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
