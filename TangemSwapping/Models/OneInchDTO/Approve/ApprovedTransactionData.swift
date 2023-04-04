//
//  ApprovedTransactionData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ApprovedTransactionData: Decodable {
    public let data: String
    public let gasPrice: String
    public let to: String
    public let value: String
}
