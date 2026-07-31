//
//  GaslessTransactionAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum GaslessTransactionAddressFactory {
    static func gaslessExecutorContractAddress(blockchain: Blockchain, isGaslessYieldEnabled: Bool) throws -> String {
        switch blockchain {
        case .ethereum:
            return isGaslessYieldEnabled ? ConstantsV2.ethereumAddress : Constants.ethereumAddress
        case .bsc:
            return isGaslessYieldEnabled ? ConstantsV2.bscAddress : Constants.bscAddress
        case .base:
            return isGaslessYieldEnabled ? ConstantsV2.baseAddress : Constants.baseAddress
        case .polygon:
            return isGaslessYieldEnabled ? ConstantsV2.polygonAddress : Constants.polygonAddress
        case .arbitrum:
            return isGaslessYieldEnabled ? ConstantsV2.arbitrumAddress : Constants.arbitrumAddress
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
        static let ethereumAddress = "0xe3014E9AB2739aDeF234B3829C79128746160178"
        static let bscAddress = "0xe1d0BF13C427C4B2e25Df0CA29E1Faa2d10458f3"
        static let baseAddress = "0x61dD8620410a2372CbE4946f9148671F38F93fC7"
        static let polygonAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let arbitrumAddress = "0x20e7016ff14Dd10f04028fE52aBBca34F44b6965"
    }

    enum ConstantsV2 {
        static let ethereumAddress = "0xb94B392b61c16Ddb7118849D4970570C07F75dD1"
        static let bscAddress = "0x96922f4b701F0138064bCcB1549B4B7B6b3447CC"
        static let baseAddress = "0xA787dd893e772c42cCe545A2560D53AcdDe251A6"
        static let polygonAddress = "0x02a35743C4170A3685271708399311801a230cf0"
        static let arbitrumAddress = "0x4E039670C679346f785D61a0e21aBe0330F1b776"
    }
}
