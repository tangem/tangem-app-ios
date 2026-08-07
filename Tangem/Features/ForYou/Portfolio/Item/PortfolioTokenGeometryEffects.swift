//
//  PortfolioTokenGeometryEffects.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

/// Matched-geometry effects that morph a portfolio asset between its collapsed row and expanded header.
struct PortfolioTokenGeometryEffects {
    let background, icon, symbol: GeometryEffectPropertiesModel

    init(namespace: Namespace.ID) {
        background = GeometryEffectPropertiesModel(
            id: Self.backgroundID,
            namespace: namespace,
            properties: .position
        )
        icon = GeometryEffectPropertiesModel(
            id: Self.iconID,
            namespace: namespace
        )
        symbol = GeometryEffectPropertiesModel(
            id: Self.symbolID,
            namespace: namespace,
            properties: .position,
            anchor: .leading
        )
    }
}

private extension PortfolioTokenGeometryEffects {
    static let backgroundID = "portfolioTokenBackground"
    static let iconID = "portfolioTokenIcon"
    static let symbolID = "portfolioTokenSymbol"
}
