//
//  PepecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct PepecoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let compressedKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let networkParams: INetwork = input.blockchain.isTestnet ? PepecoinTestnetNetworkParams() : PepecoinMainnetNetworkParams()

        let bitcoinManager = BitcoinManager(
            networkParams: networkParams,
            walletPublicKey: input.wallet.publicKey.blockchainKey,
            compressedWalletPublicKey: compressedKey,
            bip: .bip44
        )

        let unspentOutputManager: UnspentOutputManager = .pepecoin(
            address: input.wallet.defaultAddress,
            isTestnet: input.blockchain.isTestnet
        )

        let txBuilder = BitcoinTransactionBuilder(
            bitcoinManager: bitcoinManager,
            unspentOutputManager: unspentOutputManager,
            addresses: input.wallet.addresses
        )

        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })

        let providers: [ElectrumUTXONetworkProvider] = socketManagers.map {
            ElectrumUTXONetworkProvider(blockchain: input.blockchain, provider: $0, settings: Constants.electrumSettings)
        }

        let networkService = MultiUTXONetworkProvider(providers: providers)
        return PepecoinWalletManager(wallet: input.wallet, txBuilder: txBuilder, unspentOutputManager: unspentOutputManager, networkService: networkService)
    }
}

// MARK: - Constants

extension PepecoinWalletAssembly {
    enum Constants {
        /*
         This minimal rate fee for successful transaction from constant
         -  Relying on answers from blockchain developers and costs from the official application (Electron-Pepecoin).
         */

        static let electrumSettings: ElectrumUTXONetworkProvider.Settings = .init(
            recommendedFeePer1000Bytes: .init(stringValue: "0.01")!,
            normalFeeMultiplier: .init(stringValue: "1.5")!,
            priorityFeeMultiplier: .init(stringValue: "2")!
        )
    }
}
