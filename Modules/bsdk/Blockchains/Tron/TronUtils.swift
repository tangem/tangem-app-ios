//
//  TronUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct TronUtils {
    func parseBalance(response constantResult: [String], decimals: Int) throws -> Decimal {
        guard let hexValue = constantResult.first else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        // Need use 32 byte for obtain right value
        let substringHexSizeValue = String(hexValue.prefix(64))
        let bigIntValue = BigUInt(Data(hex: substringHexSizeValue))

        let formatted = EthereumUtils.formatToPrecision(
            bigIntValue,
            numberDecimals: decimals,
            formattingDecimals: decimals,
            decimalSeparator: ".",
            fallbackToScientific: false
        )

        guard let decimalValue = Decimal(stringValue: formatted) else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        return decimalValue
    }

    func convertAddressToBytes(_ base58String: String) throws -> Data {
        guard let bytes = base58String.base58CheckDecodedBytes else {
            throw TronError.failedToDecodeAddress
        }

        return Data(bytes)
    }

    func convertAddressToBytesPadded(_ base58String: String) throws -> Data {
        guard let bytes = base58String.base58CheckDecodedBytes else {
            throw TronError.failedToDecodeAddress
        }

        return Data(bytes).leadingZeroPadding(toLength: 32)
    }

    func convertAmountPadded(_ amount: Amount) throws -> Data {
        guard let amountData = amount.encoded?.leadingZeroPadding(toLength: 32) else {
            throw BlockchainSdkError.failedToGetFee
        }

        return amountData
    }
}
