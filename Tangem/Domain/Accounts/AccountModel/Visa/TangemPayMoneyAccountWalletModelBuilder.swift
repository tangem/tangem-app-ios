//
//  TangemPayMoneyAccountWalletModelBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay
import TangemVisa

struct TangemPayMoneyAccountWalletModelBuilder {
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

    private let walletModelsFactoryProvider: WalletModelsFactoryProvider

    init(walletModelsFactoryProvider: WalletModelsFactoryProvider) {
        self.walletModelsFactoryProvider = walletModelsFactoryProvider
    }

    func makeWalletModel() -> (any WalletModel)? {
        let tokenItem = TangemPayUtilities.bankingAccountUsdcTokenItem

        guard let token = tokenItem.token else {
            return nil
        }

        do {
            let wallet = try HDWalletFactory().makeWallet(
                blockchainNetwork: tokenItem.blockchainNetwork,
                keys: walletModelsFactoryProvider.keysRepository.keys
            )

            let walletManager = try GenericWalletManagerFactory().makeWalletManager(
                wallet: wallet,
                tokens: [token],
                apiList: apiListProvider.apiList
            )

            return walletModelsFactoryProvider
                .makeStandaloneWalletModelsFactory()
                .makeWalletModels(
                    for: [tokenItem.amountType],
                    walletManager: walletManager,
                    blockchainNetwork: tokenItem.blockchainNetwork,
                    targetAccountDerivationPath: nil
                )
                .first
        } catch AnyWalletFactoryError.noDerivation {
            return nil
        } catch {
            VisaLogger.error("Failed to make the Money Account wallet model", error: error)
            return nil
        }
    }
}
