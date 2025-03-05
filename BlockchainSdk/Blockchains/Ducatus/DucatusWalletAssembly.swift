//
//  DucatusWalletAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DucatusWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: input.wallet.publicKey.blockchainKey, compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(), bip: .bip44)

        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
        let networkService = DucatusNetworkService(configuration: input.networkConfig)

        return DucatusWalletManager(wallet: input.wallet, txBuilder: txBuilder, networkService: networkService)
    }
}
