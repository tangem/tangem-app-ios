//
//  TronStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TronStakeKitTransactionHelper {
    func prepareForSign(_ unsignedData: String) throws -> TronPresignedInput {
        let rawData = try Protocol_Transaction.raw(serializedData: Data(hex: unsignedData))
        let hash = try rawData.serializedData().sha256()
        return .init(rawData: rawData, hash: hash)
    }
}
