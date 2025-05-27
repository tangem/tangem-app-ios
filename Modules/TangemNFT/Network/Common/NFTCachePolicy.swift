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
        switch self {
        case .always:
            return true
        case .never:
            return false
        }
    }

    var isCacheDisabled: Bool {
        switch self {
        case .always:
            return false
        case .never:
            return true
        }
    }
}
