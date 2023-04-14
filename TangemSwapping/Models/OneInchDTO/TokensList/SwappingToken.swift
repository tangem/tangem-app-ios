//
//  SwappingToken.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingToken: Decodable {
    public let symbol: String
    public let name: String
    public let decimals: Int
    public let address: String
    public let logoURI: String
    public let tags: [String]
    public let eip2612: Bool?
    public let isFoT: Bool?
    public let domainVersion: String?
    public let synth: Bool?
    public let displayedSymbol: String?
}
