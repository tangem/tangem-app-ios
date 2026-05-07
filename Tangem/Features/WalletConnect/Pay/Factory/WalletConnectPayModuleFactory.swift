//
//  WalletConnectPayModuleFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

@MainActor
enum WalletConnectPayModuleFactory {
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository
    @Injected(\.walletConnectPayService) private static var payService: any WalletConnectPayService

    static func makePayViewModel(for link: WalletConnectPayLink) -> WalletConnectPayViewModel? {
        guard FeatureProvider.isAvailable(.walletConnectPay) else {
            return nil
        }

        return WalletConnectPayViewModel(
            link: link,
            userWalletRepository: userWalletRepository,
            makeInteractor: makeInteractor
        )
    }

    private static func makeInteractor(
        userWalletModel: any UserWalletModel,
        account: any CryptoAccountModel
    ) -> WalletConnectPayInteractor {
        let actionDispatcher = WalletConnectPayActionDispatcher(
            userWalletModel: userWalletModel,
            accountId: account.id.walletConnectIdentifierString
        )

        return WalletConnectPayInteractor(
            loadOptions: WalletConnectPayLoadOptionsUseCase(payService: payService),
            loadActions: WalletConnectPayLoadActionsUseCase(payService: payService),
            signActions: WalletConnectPaySignActionsUseCase(actionDispatcher: actionDispatcher),
            confirmPayment: WalletConnectPayConfirmUseCase(payService: payService)
        )
    }

    static func makeWarningToast(with message: String) -> Toast<WarningToast> {
        Toast(view: WarningToast(text: message))
    }
}
