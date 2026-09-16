//
//  TangemPayOfframpBankDetails.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

struct TangemPayOfframpBankDetails: Equatable {
    let name: String
    let line1: String
    let city: String
    let region: TangemPayGeoRegion
    let postalCode: String
}
