//
//  BitcoinCashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct BitcoinCashWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try BitcoinWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams(),
                walletPublicKey: compressed,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )

            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)

            // [REDACTED_TODO_COMMENT]
            // Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
            let providers: [AnyBitcoinNetworkProvider] = input.apiInfo.reduce(into: []) { partialResult, providerType in
                switch providerType {
                case .nowNodes:
                    if let addressService = AddressServiceFactory(
                        blockchain: input.blockchain
                    ).makeAddressService() as? BitcoinCashAddressService {
                        partialResult.append(
                            networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                                with: input,
                                for: .nowNodes,
                                bitcoinCashAddressService: addressService
                            ).eraseToAnyBitcoinNetworkProvider()
                        )
                    }
                case .getBlock:
                    if let addressService = AddressServiceFactory(
                        blockchain: input.blockchain
                    ).makeAddressService() as? BitcoinCashAddressService {
                        partialResult.append(
                            networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                                with: input,
                                for: .getBlock,
                                bitcoinCashAddressService: addressService
                            ).eraseToAnyBitcoinNetworkProvider()
                        )
                    }
                case .blockchair:
                    partialResult.append(
                        contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                            endpoint: .bitcoinCash,
                            with: input
                        )
                    )
                default:
                    return
                }
            }

            $0.networkService = BitcoinCashNetworkService(providers: providers)
        }
    }
}
