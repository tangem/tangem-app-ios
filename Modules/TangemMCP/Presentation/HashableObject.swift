//
//  HashableObject.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol HashableObject: AnyObject, Hashable {}

extension HashableObject {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
