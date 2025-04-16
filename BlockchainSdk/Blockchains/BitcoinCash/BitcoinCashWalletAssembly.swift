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
        let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
        let networkParams: UTXONetworkParams = input.wallet.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
        let bitcoinManager = BitcoinManager(
            networkParams: input.wallet.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams(),
            walletPublicKey: compressed,
            compressedWalletPublicKey: compressed,
            bip: .bip44
        )

        let unspentOutputManager: UnspentOutputManager = .bitcoinCash(
            address: input.wallet.defaultAddress,
            isTestnet: input.wallet.blockchain.isTestnet
        )
        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        // [REDACTED_TODO_COMMENT]
        // Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
        let providers: [UTXONetworkProvider] = input.networkInput.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .nowNodes,
                        bitcoinCashAddressService: BitcoinCashAddressService(networkParams: networkParams)
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input.networkInput,
                        for: .getBlock,
                        bitcoinCashAddressService: BitcoinCashAddressService(networkParams: networkParams)
                    )
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .bitcoinCash,
                        with: input.networkInput
                    )
                )
            default:
                return
            }
        }

        let networkService = BitcoinCashNetworkService(providers: providers)
        return BitcoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
