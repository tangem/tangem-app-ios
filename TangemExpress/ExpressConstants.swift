//
//  ExpressConstants.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Fee

public typealias BSDKFee = BlockchainSdk.Fee

public enum ExpressConstants {
    public static let coinContractAddress = "0"

    public static let expressProvidersFCAWarningList: [String] = [
        "simpleswap",
        "changenow",
        "okx-cross-chain",
        "okx-on-chain",
        "changelly",
    ]
}
