//
//  WCSupportedNamespaces+WCUtils.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension WCUtils {
    enum WCSupportedNamespaces: String, CaseIterable {
        case eip155
        case solana

        init?(rawValue: String) {
            switch rawValue.lowercased() {
            case "eip155": self = .eip155
            case "solana": self = .solana
            default: return nil
            }
        }
    }
}
