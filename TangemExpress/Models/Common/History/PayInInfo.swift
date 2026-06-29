//
//  PayInInfo.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PayInInfo: Hashable {
    public let address: String
    public let extraId: String?
    public let hash: String?

    public init(
        address: String,
        extraId: String?,
        hash: String?
    ) {
        self.address = address
        self.extraId = extraId
        self.hash = hash
    }
}
