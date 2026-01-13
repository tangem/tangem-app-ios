//
//  TangemPaySetPayEnabledRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPaySetPayEnabledRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case isTangemPayEnabled = "is_tangem_pay_enabled"
    }

    /// at the moment we can only set this flag to false from client
    public let isTangemPayEnabled = false
}
