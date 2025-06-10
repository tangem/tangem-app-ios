//
//  WalletError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemLocalization

public enum WalletError: Error, LocalizedError {
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
        case .empty:
            return "Empty"
        case .failedToCalculateTxSize,
             .failedToParseNetworkResponse,
             .blockchainUnavailable,
             .accountNotActivated,
             .addressesIsEmpty:
            return Localization.genericErrorCode(errorCodeDescription)
        }
    }

    public var errorCode: Int {
        switch self {
        case .noAccount:
            return 1
        case .failedToGetFee:
            return 2
        case .failedToBuildTx:
            return 3
        case .failedToParseNetworkResponse:
            return 4
        case .failedToSendTx:
            return 5
        case .failedToCalculateTxSize:
            return 6
        case .empty:
            return 7
        case .blockchainUnavailable:
            return 8
        case .accountNotActivated:
            return 9
        case .addressesIsEmpty:
            return 10
        }
    }

    private var errorCodeDescription: String {
        return "Wallet error \(errorCode)"
    }
}

extension WalletError: ErrorCodeProviding {}
