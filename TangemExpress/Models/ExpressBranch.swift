//
//  ExpressBranch.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum ExpressBranch: String, Hashable, CaseIterable {
    case swap
    case onramp

    var supportedProviderTypes: Set<ExpressProviderType> {
        switch self {
        case .swap:
            [
                .dex,
                .cex,
                .dexBridge,
            ]
        case .onramp:
            [
                .onramp,
            ]
        }
    }
}
