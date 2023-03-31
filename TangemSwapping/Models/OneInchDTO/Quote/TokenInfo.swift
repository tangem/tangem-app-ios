//
//  TokenInfo.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TokenInfo: Decodable {
    public let symbol: String
    public let name: String
    public let address: String
    public let decimals: Int
    public let logoURI: String
}
