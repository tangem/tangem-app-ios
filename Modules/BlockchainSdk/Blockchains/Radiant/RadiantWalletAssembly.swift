//
//  RadiantWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct RadiantWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: input.wallet.blockchain, keysConfig: input.networkInput.keysConfig)
            .resolveProviders(apiInfos: input.networkInput.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })

        let providers: [ElectrumUTXONetworkProvider] = socketManagers.map {
            ElectrumUTXONetworkProvider(
                blockchain: input.wallet.blockchain,
                provider: $0,
                converter: .init(lockingScriptBuilder: .radiant()),
                settings: Constants.electrumSettings
            )
        }

        let publicKey = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

        let unspentOutputManager: UnspentOutputManager = .radiant(address: input.wallet.defaultAddress)
        let transactionBuilder = try RadiantTransactionBuilder(
            walletPublicKey: publicKey,
            unspentOutputManager: unspentOutputManager,
            decimalValue: input.wallet.blockchain.decimalValue
        )

        return RadiantWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            unspentOutputManager: unspentOutputManager,
            networkService: MultiUTXONetworkProvider(
                providers: providers,
                blockchainName: Blockchain.radiant(testnet: false).displayName
            )
        )
    }
}

// MARK: - Constants

extension RadiantWalletAssembly {
    enum Constants {
        /*
         This minimal rate fee for successful transaction from constant
         -  Relying on answers from blockchain developers and costs from the official application (Electron-Radiant).
         - 10000 satoshi per byte or 0.1 RXD per KB.
         */

        static let electrumSettings: ElectrumUTXONetworkProvider.Settings = .init(
            recommendedFeePer1000Bytes: .init(stringValue: "0.1")!,
            normalFeeMultiplier: .init(stringValue: "1.5")!,
            priorityFeeMultiplier: .init(stringValue: "2")!
        )
    }
}
