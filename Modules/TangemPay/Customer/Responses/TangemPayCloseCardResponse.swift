//
//  TangemPayCloseCardResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCloseCardResponse: Decodable {
    public let orderId: String
    public let status: TangemPayOrderResponse.Status
}
