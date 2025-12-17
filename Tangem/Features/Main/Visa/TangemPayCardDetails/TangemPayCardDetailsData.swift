//
//  TangemPayCardDetailsData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayCardDetailsData: Equatable {
    let number: String
    let expirationDate: String
    let cvc: String
    let isPINSet: Bool
}
