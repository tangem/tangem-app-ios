//
//  NFTCachePolicy.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum NFTCachePolicy {
    case always
    case never
}

// MARK: - Convenience extensions

public extension NFTCachePolicy {
    var isCacheEnabled: Bool {
        if case .always = self {
            return true
        }
        return false
    }

    var isCacheDisabled: Bool {
        if case .never = self {
            return true
        }
        return false
    }
}
