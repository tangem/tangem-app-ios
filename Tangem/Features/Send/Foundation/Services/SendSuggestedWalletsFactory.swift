//
//  SendSuggestedWalletsFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SendSuggestedWalletsFactory {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    func makeSuggestedWallets(walletModel: any WalletModel) -> [SendDestinationSuggestedWallet] {
        let ignoredAddresses = walletModel.addresses.map(\.value).toSet()
        let targetNetworkId = walletModel.tokenItem.blockchain.networkId

        return userWalletRepository.models.reduce(into: []) { partialResult, userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels

            partialResult += walletModels
                .filter { walletModel in
                    let blockchain = walletModel.tokenItem.blockchain
                    let shouldBeIncluded = { blockchain.supportsCompound || !ignoredAddresses.contains(walletModel.defaultAddressString) }

                    return blockchain.networkId == targetNetworkId && walletModel.isMainToken && shouldBeIncluded()
                }
                .map { walletModel in
                    SendDestinationSuggestedWallet(name: userWalletModel.name, address: walletModel.defaultAddressString)
                }
        }
    }
}
