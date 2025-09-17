//
//  Hashable+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension Hashable {
    func toAnyHashable() -> AnyHashable {
        self as AnyHashable
    }
}
