//
//  JWTTokenHelper.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct JWTTokenHelper {
    private let customerIDClaim = "customer-id"

    func getCustomerID(from token: JWT) -> String? {
        return token.claim(name: customerIDClaim).string
    }
}
