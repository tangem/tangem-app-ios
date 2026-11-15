//
//  SelectorAvailability.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

@CaseFlagable
public enum SelectorAvailability: Hashable {
    case available
    case locked
    case unavailable(SelectorUnavailableReason)
}

public struct SelectorUnavailableReason: Hashable {
    public let badge: String?
    public let title: String
    public let message: String

    public init(badge: String?, title: String, message: String) {
        self.badge = badge
        self.title = title
        self.message = message
    }
}

public extension SelectorAvailability {
    var unavailableReason: SelectorUnavailableReason? {
        if case .unavailable(let reason) = self {
            return reason
        }

        return nil
    }
}
