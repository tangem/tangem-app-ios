//
//  ExpressWalletInfo.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressWalletInfo {
    public let id: String
    public let refcode: String?

    public init(id: String, refcode: String?) {
        self.id = id
        self.refcode = refcode
    }
}
