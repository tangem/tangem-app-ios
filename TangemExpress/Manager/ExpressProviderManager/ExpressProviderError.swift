//
//  ExpressProviderError.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderError: LocalizedError {
    case transactionDataNotFound
    case transactionSizeNotSupported
}
