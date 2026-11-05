//
//  UInt32+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension UInt32 {
    init(raw value: Int) throws {
        guard let value = UInt32(exactly: value) else {
            throw NSError(domain: "Integer overflow", code: -1)
        }

        self = value
    }
}
