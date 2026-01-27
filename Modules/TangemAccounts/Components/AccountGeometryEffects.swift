//
//  AccountGeometryEffects.swift
//  TangemAccounts
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct AccountGeometryEffects {
    public let icon: GeometryEffectPropertiesModel
    public let iconBackground: GeometryEffectPropertiesModel
    public let name: GeometryEffectPropertiesModel
    public let tokensCount: GeometryEffectPropertiesModel
    public let balance: GeometryEffectPropertiesModel
    public let background: GeometryEffectPropertiesModel

    public init(namespace: Namespace.ID) {
        icon = GeometryEffectPropertiesModel(
            id: "accountIcon",
            namespace: namespace
        )
        iconBackground = GeometryEffectPropertiesModel(
            id: "accountIconBackground",
            namespace: namespace
        )
        name = GeometryEffectPropertiesModel(
            id: "accountName",
            namespace: namespace
        )
        tokensCount = GeometryEffectPropertiesModel(
            id: "tokensCount",
            namespace: namespace,
            properties: .position,
            anchor: .leading
        )
        balance = GeometryEffectPropertiesModel(
            id: "accountBalance",
            namespace: namespace,
            properties: .position
        )
        background = GeometryEffectPropertiesModel(
            id: "expandableBackground",
            namespace: namespace
        )
    }
}
