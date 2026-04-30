//
//  TangemPayFeeResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayFeeResponse: Decodable {
    public let type: String
    public let amount: Decimal
    public let currency: String
    public let description: String
}
