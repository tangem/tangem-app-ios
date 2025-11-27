//
//  TangemPayFreezeUnfreezeResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayFreezeUnfreezeResponse: Decodable {
    public let orderId: String
    public let status: TangemPayOrderResponse.Status
}
