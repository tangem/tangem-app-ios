//
//  ManageTokensNetworkSelectorNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class ManageTokensNetworkSelectorNotificationViewModel: Identifiable, ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published Properties

    @Published var notificationInput: NotificationViewInput?

    // MARK: - Init

    // [REDACTED_TODO_COMMENT]
    init?(coinId: String) {
        guard isNeedDisplayAlert(by: coinId) else { return nil }

        notificationInput = nil

        let singleCurrencyUserWalletModels = userWalletRepository.models.filter { userWalletModel in
            return !userWalletModel.isMultiWallet
        }

        guard !singleCurrencyUserWalletModels.isEmpty else {
            // Display flow notifications if list of wallets does not supported current coinId
            displayWarningNotification(for: .walletsNotSupportedBlockchain)
            return
        }

        if let _ = singleCurrencyUserWalletModels.first(where: {
            $0.config.supportedBlockchains.map { $0.coinId }.contains(coinId)
        }) {
            return nil
        } else {
            // Display flow notifications if use only single currency wallets does not supported current coinId
            displayWarningNotification(for: .supportedOnlySingleCurrencyWallet)
            return
        }
    }

    // MARK: - Private Implementation

    private func isNeedDisplayAlert(by coinId: String) -> Bool {
        userWalletRepository.models.filter {
            $0.isMultiWallet &&
                !$0.isUserWalletLocked &&
                $0.config.supportedBlockchains.map { $0.coinId }.contains(coinId)
        }.isEmpty
    }

    private func displayWarningNotification(for event: WarningEvent) {
        let notificationsFactory = NotificationsFactory()

        notificationInput = notificationsFactory.buildNotificationInput(
            for: event,
            action: { _ in },
            buttonAction: { _, _ in },
            dismissAction: { _ in }
        )
    }
}
