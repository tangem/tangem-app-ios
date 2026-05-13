//
//  CardanoError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public enum CardanoError: Error, LocalizedError {
    case noUnspents
    case lowAda
    case derivationPathIsShort
    case assetNotFound
    case walletCoreError
    case feeParametersNotFound
    case failedToHashTransactionData

    public var errorDescription: String? {
        Localization.genericErrorCode(errorCode)
    }
}
