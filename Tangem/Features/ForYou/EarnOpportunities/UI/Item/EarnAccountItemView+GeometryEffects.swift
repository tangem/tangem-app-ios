//
//  EarnAccountItemView+GeometryEffects.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

extension EarnAccountItemView {
    /// Matched-geometry effects that morph the account card between its collapsed row and expanded header
    struct GeometryEffects {
        let background, icon, iconBackground, name: GeometryEffectPropertiesModel

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
            iconBackground = GeometryEffectPropertiesModel(
                id: Self.iconBackgroundID,
                namespace: namespace
            )
            name = GeometryEffectPropertiesModel(
                id: Self.nameID,
                namespace: namespace,
                properties: .position,
                anchor: .leading
            )
        }
    }
}

private extension EarnAccountItemView.GeometryEffects {
    static let backgroundID = "earnAccountBackground"
    static let iconID = "earnAccountIcon"
    static let iconBackgroundID = "earnAccountIconBackground"
    static let nameID = "earnAccountName"
}
