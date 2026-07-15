//
//  PayOutInfo.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PayOutInfo: Hashable {
    public let address: String
    public let hash: String?

    public init(
        address: String,
        hash: String?
    ) {
        self.address = address
        self.hash = hash
    }
}
