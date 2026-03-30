//
//  WalletModelFeature.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemMacro

@CaseFlagable
enum WalletModelFeature {
    case nft(networkService: NFTNetworkService)

    case dynamicAddresses(addressesManager: DynamicAddressesManager)

    @available(*, unavailable, message: "This feature is not implemented yet")
    case staking

    @available(*, unavailable, message: "This feature is not implemented yet")
    case transactionHistory
}

extension [WalletModelFeature] {
    var dynamicAddressesManager: DynamicAddressesManager? {
        for feature in self {
            if case .dynamicAddresses(let addressesManager) = feature {
                return addressesManager
            }
        }

        return nil
    }
}
