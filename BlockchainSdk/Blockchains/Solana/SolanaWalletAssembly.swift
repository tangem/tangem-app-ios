//
//  SolanaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import SolanaSwift
import TangemNetworkUtils

struct SolanaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let apiList = APIList(dictionaryLiteral: (input.wallet.blockchain.networkId, input.networkInput.apiInfo))

        let serviceFactory = WalletNetworkServiceFactory(
            blockchainSdkKeysConfig: input.networkInput.keysConfig,
            tangemProviderConfig: input.networkInput.tangemProviderConfig,
            apiList: apiList
        )

        return try SolanaWalletManager(wallet: input.wallet)
            .then {
                let networkService: SolanaNetworkService = try serviceFactory.makeServiceWithType(for: input.wallet.blockchain)
                $0.networkService = networkService
            }
    }
}
