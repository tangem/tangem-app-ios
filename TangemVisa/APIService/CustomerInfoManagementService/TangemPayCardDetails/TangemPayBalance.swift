//
//  TangemPayBalance.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayBalance: Decodable, Equatable {
    public let currency: String
    public let availableBalance: Decimal
}
