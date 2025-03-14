//
//  MarketsTokenDetailsPortfolioCoordinatorFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsPortfolioCoordinatorFactory {
    // MARK: - Utils

    private func buildExchangeCryptoUtility(for walletModel: any WalletModel) -> ExchangeCryptoUtility {
        return ExchangeCryptoUtility(
            blockchain: walletModel.tokenItem.blockchain,
            address: walletModel.defaultAddressString,
            amountType: walletModel.tokenItem.amountType
        )
    }

    // MARK: - Make

    func makeExpressCoordinator(
        for walletModel: any WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> ExpressCoordinator {
        let input = CommonExpressModulesFactory.InputModel(userWalletModel: userWalletModel, initialWalletModel: walletModel)
        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        return coordinator
    }

    func makeBuyURL(
        for walletModel: any WalletModel,
        with userWalletModel: UserWalletModel
    ) -> URL? {
        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)
        return exchangeUtility.buyURL
    }

    func makeSellCryptoRequest(from closeURL: URL, with walletModel: any WalletModel) -> SellCryptoRequest? {
        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)
        return exchangeUtility.extractSellCryptoRequest(from: closeURL.absoluteString)
    }
}
