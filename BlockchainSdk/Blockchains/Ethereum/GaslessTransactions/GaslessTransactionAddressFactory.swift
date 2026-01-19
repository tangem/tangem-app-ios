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
        static let ethereumAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
        static let bscAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
        static let baseAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
        static let polygonAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
        static let arbitrumAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
        static let xdcAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
        static let optimismAddress = "0x041760838DaC2AC9013D26C9550daa519bd29bB9"
    }
}
