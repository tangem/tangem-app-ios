//
//  ExpressConstants.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Fee
import struct BlockchainSdk.ApproveTransactionData

public typealias BSDKFee = BlockchainSdk.Fee
public typealias BSDKApproveTransactionData = BlockchainSdk.ApproveTransactionData

public enum ExpressConstants {
    public static let coinContractAddress = "0"

    public static let expressProvidersFCAWarningList: [String] = [
        "simpleswap",
        "changenow",
        "okx-cross-chain",
        "okx-on-chain",
        "changelly",
    ]

    public static let yieldModuleDEXProviderIds: Set<ExpressProvider.Id> = [
        "1inch",
        "lifi",
        "okx-cross-chain",
        "okx-on-chain",
    ]

    public static let swapProviderTypes: [ExpressProviderType] = [.dex, .cex, .dexBridge]
}
