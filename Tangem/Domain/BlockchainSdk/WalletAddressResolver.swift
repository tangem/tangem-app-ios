//
//  WalletAddressResolver.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import Foundation
import TangemSdk
import BlockchainSdk

// MARK: - NetworkAddressPair

struct NetworkAddressPair {
    let blockchainNetwork: BlockchainNetwork
    let address: String
}

// MARK: - WalletAddressResolver

/// Resolves a single blockchain address from key infos. Used by features (e.g. initial token sync) that need [network: address] pairs.
struct WalletAddressResolver {
    /// Resolves address for the given blockchain using the provided key infos.
    /// - Throws: `WalletAddressResolver.Error` if the curve has no key, derived keys are missing, or address generation fails.
    func resolveAddress(
        for blockchainNetwork: BlockchainNetwork,
        keyInfos: [KeyInfo]
    ) throws -> NetworkAddressPair {
        let blockchain = blockchainNetwork.blockchain

        switch blockchain {
        case .hedera:
            throw Error.unsupportedBlockchain(blockchain)
        default:
            break
        }

        do {
            let dataStorage = UserDefaultsBlockchainDataStorage(suiteName: AppEnvironment.current.blockchainDataStorageSuiteName)
            let factory = GenericWalletFactory(dataStorage: dataStorage)
            let wallet = try factory.makeWallet(blockchainNetwork: blockchainNetwork, keys: keyInfos)
            return NetworkAddressPair(blockchainNetwork: blockchainNetwork, address: wallet.defaultAddress.value)
        } catch {
            throw Error.addressGenerationFailed(blockchain: blockchain, underlying: error)
        }
    }
}

extension WalletAddressResolver {
    enum Error: Swift.Error {
        case unsupportedBlockchain(Blockchain)
        case addressGenerationFailed(blockchain: Blockchain, underlying: Swift.Error)
    }
}
