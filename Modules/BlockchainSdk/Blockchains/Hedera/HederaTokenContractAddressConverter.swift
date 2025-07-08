//
//  HederaTokenContractAddressConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hedera

public struct HederaTokenContractAddressConverter {
    public func convertFromEVMToHedera(_ evmAddress: String) throws -> String {
        return "" // [REDACTED_TODO_COMMENT]
    }

    public func convertFromHederaToEVM(_ hederaAddress: String) throws -> String {
        return try AccountId
            .fromString(hederaAddress)
            .toSolidityAddress()
            .addHexPrefix()
    }

    public init() {}
}
