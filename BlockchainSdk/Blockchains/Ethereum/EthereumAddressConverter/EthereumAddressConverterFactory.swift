//
//  EthereumAddressConverterFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct EthereumAddressConverterFactory {
    public init() {}

    public func makeConverter(for blockchain: Blockchain) -> EthereumAddressConverter {
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
