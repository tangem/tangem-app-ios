//
//  MCPIntentTokenIconView.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct MCPIntentTokenIconView: View {
    let state: MCPIntentTokenIconState
    let hasAppeared: Bool

    var body: some View {
        TokenIconV2(
            tokenIconInfo: TokenIconInfo(
                name: state.accessibilityIdentifier,
                blockchainIconAsset: state.networkIconAsset,
                imageURL: state.iconURL,
                isCustom: state.isCustom,
                customTokenColor: nil
            ),
            size: .size56
        )
        .animation(nil, value: hasAppeared)
        .geometryGroupBackport()
    }
}
