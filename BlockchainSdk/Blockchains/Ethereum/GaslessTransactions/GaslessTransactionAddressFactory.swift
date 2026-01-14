//
//  GaslessTransactionAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum GaslessTransactionAddressFactory {
    static func gaslessExecutorContractAddress(blockchain: Blockchain) throws -> String {
        switch blockchain {
        case .ethereum:
            return Constants.ethereumAddress
        case .bsc:
            return Constants.bscAddress
        case .base:
            return Constants.baseAddress
        case .polygon:
            return Constants.polygonAddress
        case .arbitrum:
            return Constants.arbitrumAddress
        case .xdc:
            return Constants.xdcAddress
        case .optimism:
            return Constants.optimismAddress
        default:
            throw GaslessTransactionAddressFactoryError.addressNotDefined(blockchain.displayName)
        }
    }
}

extension GaslessTransactionAddressFactory {
    enum GaslessTransactionAddressFactoryError: Error {
        case addressNotDefined(String)
    }
}

extension GaslessTransactionAddressFactory {
    enum Constants {
        static let ethereumAddress = "0xd8972a45616bEC62cB9687e38a99D763c0879B0d"
        static let bscAddress = "0xd8972a45616bEC62cB9687e38a99D763c0879B0d"
        static let baseAddress = "0xd8972a45616bEC62cB9687e38a99D763c0879B0d"
        static let polygonAddress = "0x2Bfd00f7D053E7a665d1767f08c5a57B3F52Ec89"
        static let arbitrumAddress = "0xd8972a45616bEC62cB9687e38a99D763c0879B0d"
        static let xdcAddress = "0xd8972a45616bEC62cB9687e38a99D763c0879B0d"
        static let optimismAddress = "0xd8972a45616bEC62cB9687e38a99D763c0879B0d"
    }
}
