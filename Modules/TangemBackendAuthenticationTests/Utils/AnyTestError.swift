//
//  AnyTestError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.UUID

struct AnyTestError: Error, Equatable {
    var id = UUID()

    static func ~= (lhs: Self, rhs: some Error) -> Bool {
        guard let rhsAnyTestError = rhs as? Self else {
            return false
        }

        return lhs == rhsAnyTestError
    }
}
