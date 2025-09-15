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

    private func buildSellCryptoUtility(for walletModel: any WalletModel) -> SellCryptoUtility {
        return SellCryptoUtility(
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

    func makeSellCryptoRequest(from closeURL: URL, with walletModel: any WalletModel) -> SellCryptoRequest? {
        let sellUtility = buildSellCryptoUtility(for: walletModel)
        return sellUtility.extractSellCryptoRequest(from: closeURL.absoluteString)
    }
}
