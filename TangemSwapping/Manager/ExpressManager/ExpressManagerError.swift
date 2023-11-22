//
//  ExpressManagerError.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressManagerError: String, LocalizedError {
    case amountNotFound
    case contractAddressNotFound
    case availablePairNotFound
    case pairNotFound
    case selectedProviderNotFound
    case quotesNotFound
    case availableQuotesForProviderNotFound

    public var errorDescription: String? {
        rawValue
    }
}
