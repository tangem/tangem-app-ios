//
//  ExpressFeeProviderError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ExpressFeeProviderError: Error {
    case feeNotFound
    case ethereumNetworkProviderNotFound

    case ethereumTokenFeeLoaderNotFound
    case solanaTokenFeeLoaderNotFound
}
