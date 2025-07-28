//
//  SolanaStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class SolanaStakeKitTransactionHelper {
    func prepareForSign(_ unsignedData: String) throws -> Data {
        let (transaction, _) = try SolanaTransactionHelper().removeSignaturesPlaceholders(from: Data(hex: unsignedData))
        return transaction
    }

    func prepareForSend(_ unsignedData: String, signature: Data) throws -> String {
        let prepared = try prepareForSign(unsignedData)
        let dataToSign = Data([UInt8(1)] + signature + prepared)
        return dataToSign.base64EncodedString()
    }
}
