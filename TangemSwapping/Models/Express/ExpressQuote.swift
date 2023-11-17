//
//  ExpressQuote.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressQuote: Hashable {
    public let expectAmount: Decimal
    public let minAmount: Decimal
    public let allowanceContract: String?
}
