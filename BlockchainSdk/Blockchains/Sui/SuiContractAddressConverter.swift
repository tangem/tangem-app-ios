//
//  SuiContractAddressConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct SuiContractAddressConverter {
    public init() {}

    public func convertIfNeeded(contractAddress: String) -> String {
        do {
            let normalizeContractType = try SuiCoinObject.CoinType(string: contractAddress).string
            return normalizeContractType
        } catch {
            return contractAddress
        }
    }
}
