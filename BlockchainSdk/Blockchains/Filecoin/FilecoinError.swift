//
//  FilecoinError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum FilecoinError: Error {
    case filecoinFeeParametersNotFound
    case failedToConvertAmountToBigUInt
    case failedToGetDataFromJSON
}
