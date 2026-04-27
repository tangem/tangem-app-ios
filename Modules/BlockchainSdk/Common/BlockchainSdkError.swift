//
//  BlockchainSdkError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import Moya

public enum BlockchainSdkError: LocalizedError {
    case noAPIInfo
    case noAccount(message: String, amountToCreate: Decimal)
    case failedToGetFee
    case failedToBuildTx
    case failedToParseNetworkResponse(Response? = nil)
    case failedToSendTx
    case failedToCalculateTxSize
    case empty
    case blockchainUnavailable(underlyingError: Error)
    case accountNotActivated
    case addressesIsEmpty
    case signatureCountNotMatched
    case failedToCreateMultisigScript
    case failedToConvertPublicKey
    case notImplemented
    case decodingFailed
    case failedToLoadFee
    case failedToLoadTxDetails
    case failedToFindTransaction
    case failedToFindTxInputs
    case feeForPushTxNotEnough
    case networkProvidersNotSupportsRbf
    case networkUnavailable
    case twMakeAddressFailed
    case noTrustlineAtDestination

    public var errorDescription: String? {
        switch self {
        case .noAccount(let message, _):
            return message
        case .failedToGetFee:
            return Localization.commonFeeError
        case .failedToBuildTx:
            return Localization.commonBuildTxError
        case .failedToSendTx:
            return Localization.commonSendTxError
        case .failedToLoadFee:
            return Localization.commonFeeError
        default:
            return Localization.genericErrorCode(errorCode)
        }
    }
}
