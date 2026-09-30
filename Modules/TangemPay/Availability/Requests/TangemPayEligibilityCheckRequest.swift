//
//  TangemPayEligibilityCheckRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayEligibilityCheckRequest: Encodable {
    let product: TangemPayProduct
    let country: String
    let region: String?
}
