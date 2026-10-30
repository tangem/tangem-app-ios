//
//  MCPIntentTokenIconState.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct TangemAssets.ImageType

struct MCPIntentTokenIconState: Equatable {
    let iconURL: URL?
    let networkIconAsset: ImageType?
    let isCustom: Bool
    let accessibilityIdentifier: String

    init(token: MCPToken) {
        switch token.kind {
        case .nativeCoin(let iconURL):
            self.iconURL = iconURL
            networkIconAsset = nil
        case .token(let iconURL):
            self.iconURL = iconURL
            networkIconAsset = token.network.iconAsset
        case .customToken:
            iconURL = nil
            networkIconAsset = token.network.iconAsset
        }

        isCustom = token.kind == .customToken
        accessibilityIdentifier = token.displayName
    }
}
