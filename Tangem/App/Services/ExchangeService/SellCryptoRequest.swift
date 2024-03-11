//
//  SellCryptoRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SellCryptoRequest {
    let currencyCode: String
    let amount: Decimal
    let targetAddress: String
    let tag: String?
}
