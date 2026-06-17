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
                address: input.wallet.address,
                ttl: Constants.ttl
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

// MARK: - Constants

private extension CardanoWalletAssembly {
    enum Constants {
        // Transaction validity time. Currently we are using absolute values.
        // At 16 April 2023 was 90007700 slot number.
        // We need to rework this logic to use relative validity time.
        // [REDACTED_TODO_COMMENT]
        // This can be constructed using absolute ttl slot from `/metadata` endpoint.
        static let ttl: UInt64 = 1900000000
    }
}
