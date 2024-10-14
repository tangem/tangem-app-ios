//
//  LitecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct LitecoinWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try BitcoinWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: .bip84)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            let providers: [AnyBitcoinNetworkProvider] = input.apiInfo.reduce(into: []) { partialResult, providerType in
                switch providerType {
                case .nowNodes:
                    partialResult.append(
                        networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider()
                    )
                case .getBlock:
                    partialResult.append(
                        networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider()
                    )
                case .blockchair:
                    partialResult.append(
                        contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .litecoin, with: input)
                    )
                case .blockcypher:
                    partialResult.append(
                        networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .litecoin, with: input).eraseToAnyBitcoinNetworkProvider()
                    )
                default:
                    return
                }
            }
            
            $0.networkService = LitecoinNetworkService(providers: providers)
        }
    }
    
}
