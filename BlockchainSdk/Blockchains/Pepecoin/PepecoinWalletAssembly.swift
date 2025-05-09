//
//  PepecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct PepecoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.wallet.blockchain
        let unspentOutputManager: UnspentOutputManager = .pepecoin(
            address: input.wallet.defaultAddress,
            isTestnet: input.wallet.blockchain.isTestnet
        )

        let txBuilder = BitcoinTransactionBuilder(
            network: blockchain.isTestnet ? PepecoinTestnetNetworkParams() : PepecoinMainnetNetworkParams(),
            unspentOutputManager: unspentOutputManager
        )

        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })

        let providers: [ElectrumUTXONetworkProvider] = socketManagers.map {
            ElectrumUTXONetworkProvider(
                blockchain: input.wallet.blockchain,
                provider: $0,
                converter: .init(lockingScriptBuilder: .pepecoin(isTestnet: input.wallet.blockchain.isTestnet)),
                settings: Constants.electrumSettings
            )
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
