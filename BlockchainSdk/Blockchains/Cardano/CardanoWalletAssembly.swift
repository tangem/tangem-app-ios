//
//  CardanoWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardanoWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return CardanoWalletManager(wallet: input.wallet).then {
            $0.transactionBuilder = CardanoTransactionBuilder(
                address: input.wallet.address
            )
            let cardanoResponseMapper = CardanoResponseMapper()

            let linkResolver = APINodeInfoResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            let providers: [AnyCardanoNetworkProvider] = input.networkInput.apiInfo.compactMap {
                guard let nodeInfo = linkResolver.resolve(for: $0) else {
                    return nil
                }

                switch $0 {
                case .getBlock, .tangemRosetta, .nowNodes:
                    return RosettaNetworkProvider(
                        url: nodeInfo.url,
                        configuration: input.networkInput.tangemProviderConfig,
                        cardanoResponseMapper: cardanoResponseMapper
                    )
                    .eraseToAnyCardanoNetworkProvider()
                case .adalite:
                    return AdaliteNetworkProvider(
                        url: nodeInfo.url,
                        configuration: input.networkInput.tangemProviderConfig,
                        cardanoResponseMapper: cardanoResponseMapper
                    ).eraseToAnyCardanoNetworkProvider()
                case .mock:
                    return RosettaNetworkProvider(
                        url: nodeInfo.url,
                        configuration: input.networkInput.tangemProviderConfig,
                        cardanoResponseMapper: cardanoResponseMapper
                    )
                    .eraseToAnyCardanoNetworkProvider()
                default:
                    return nil
                }
            }

            $0.networkService = CardanoNetworkService(providers: providers)
        }
    }
}
