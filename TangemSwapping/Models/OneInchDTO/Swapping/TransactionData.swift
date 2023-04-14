//
//  TransactionData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionData: Codable {
    public let from: String
    public let to: String
    public let data: String
    public let value: String
    public let gas: Int
    public let gasPrice: String
}
