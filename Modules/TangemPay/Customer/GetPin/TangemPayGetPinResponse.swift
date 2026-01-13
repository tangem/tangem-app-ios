//
//  TangemPayGetPinResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayGetPinResponse: Decodable {
    public let encryptedPin: String
    public let iv: String
}
