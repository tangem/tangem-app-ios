//
//  SwapReferrerAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SwapReferrerAccount: Decodable {
    let address: String
    let fee: Decimal
}
