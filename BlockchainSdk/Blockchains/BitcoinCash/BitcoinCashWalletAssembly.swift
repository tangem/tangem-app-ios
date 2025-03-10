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
        let networkParams: INetwork = input.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
        let bitcoinManager = BitcoinManager(
            networkParams: networkParams,
            walletPublicKey: compressed,
            compressedWalletPublicKey: compressed,
            bip: .bip44
        )

        let unspentOutputManager = CommonUnspentOutputManager(decimalValue: input.blockchain.decimalValue)
        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        // [REDACTED_TODO_COMMENT]
        // Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
        let providers: [UTXONetworkProvider] = input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input,
                        for: .nowNodes,
                        bitcoinCashAddressService: BitcoinCashAddressService(networkParams: networkParams)
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input,
                        for: .getBlock,
                        bitcoinCashAddressService: BitcoinCashAddressService(networkParams: networkParams)
                    )
                )
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

        let networkService = BitcoinCashNetworkService(providers: providers)
        return BitcoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}
