//
//  EthereumAddressConverterFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumAddressConverterFactory {
    func makeConverter(for blockchain: Blockchain) -> EthereumAddressConverter {
        switch blockchain {
        case .xdc:
            return XDCAddressConverter()
        case .decimal:
            return DecimalAddressConverter()
        default:
            return IdentityEthereumAddressConverter()
        }
    }
}
