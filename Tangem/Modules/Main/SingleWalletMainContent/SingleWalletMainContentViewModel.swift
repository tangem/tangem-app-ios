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
    private let rateAppController: RateAppController

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()

    private var updateSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    private weak var mainViewDelegate: MainViewDelegate?

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        userWalletNotificationManager: NotificationManager,
        tokenNotificationManager: NotificationManager,
        rateAppController: RateAppController,
        tokenRouter: SingleTokenRoutable,
        mainViewDelegate: MainViewDelegate?
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        self.rateAppController = rateAppController
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

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        mainViewDelegate?.present(actionSheet: actionSheet)
    }

    private func bind() {
        let userWalletNotificationsPublisher = userWalletNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .share(replay: 1)

        userWalletNotificationsPublisher
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        rateAppController.bind(
            isPageSelectedPublisher: isPageSelectedSubject,
            notificationsPublisher: userWalletNotificationsPublisher
        )
    }
}

// MARK: - MainViewPage protocol conformance

extension SingleWalletMainContentViewModel: MainViewPage {
    func onPageAppear() {
        isPageSelectedSubject.send(true)
    }

    func onPageDisappear() {
        isPageSelectedSubject.send(false)
    }
}
