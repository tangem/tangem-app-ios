//
//  GaslessTransactionAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum GaslessTransactionAddressFactory {
    static func gaslessExecutorContractAddress(blockchain: Blockchain, version: GaslessExecutorVersion) throws -> String {
        switch version {
        case .batchCapable:
            return try batchCapableAddress(blockchain: blockchain)
        }
    }

    private static func batchCapableAddress(blockchain: Blockchain) throws -> String {
        switch blockchain {
        case .ethereum: BatchCapableConstants.ethereumAddress
        case .bsc: BatchCapableConstants.bscAddress
        case .base: BatchCapableConstants.baseAddress
        case .polygon: BatchCapableConstants.polygonAddress
        case .arbitrum: BatchCapableConstants.arbitrumAddress
        default: throw GaslessTransactionAddressFactoryError.addressNotDefined(blockchain.displayName)
        }
    }
}

extension GaslessTransactionAddressFactory {
    enum GaslessTransactionAddressFactoryError: Error {
        case addressNotDefined(String)
    }
}

extension GaslessTransactionAddressFactory {
    /// `Tangem7702GaslessExecutor` production deployments, taken from the `tangem-gasless-transactions-contracts`
    /// repository. Each set matches one `GaslessExecutorVersion`; when adding a deployment, check the contract's
    /// EIP-712 type strings against `GaslessTransactionsEIP712Util` — a changed struct needs a new version case,
    /// not a new address in an existing set.
    enum BatchCapableConstants {
        static let ethereumAddress = "0xb94B392b61c16Ddb7118849D4970570C07F75dD1"
        static let bscAddress = "0x96922f4b701F0138064bCcB1549B4B7B6b3447CC"
        static let baseAddress = "0xA787dd893e772c42cCe545A2560D53AcdDe251A6"
        static let polygonAddress = "0x02a35743C4170A3685271708399311801a230cf0"
        static let arbitrumAddress = "0x4E039670C679346f785D61a0e21aBe0330F1b776"
    }
}
