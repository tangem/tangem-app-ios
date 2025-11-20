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
        dismissAction: @escaping ExpressCoordinator.DismissAction,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> ExpressCoordinator {
        let input = ExpressDependenciesInput(
            userWalletInfo: userWalletModel.userWalletInfo,
            source: ExpressInteractorWalletWrapper(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel),
            destination: .loadingAndSet
        )

        let factory = CommonExpressModulesFactory(input: input)
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
