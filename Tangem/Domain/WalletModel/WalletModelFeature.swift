//
//  WalletModelFeature.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

enum WalletModelFeature {
    case nft(networkService: NFTNetworkService)

    case dynamicAddresses(addressesManager: DynamicAddressesManager)

    @available(*, unavailable, message: "This feature is not implemented yet")
    case staking

    @available(*, unavailable, message: "This feature is not implemented yet")
    case transactionHistory
}
