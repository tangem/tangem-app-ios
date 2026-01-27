//
//  GeometryEffect.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public struct GeometryEffectPropertiesModel {
    let id: String
    let namespace: Namespace.ID
    let properties: MatchedGeometryProperties
    let anchor: UnitPoint
    let isSource: Bool

    public init(
        id: String,
        namespace: Namespace.ID,
        properties: MatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center,
        isSource: Bool = true
    ) {
        self.id = id
        self.namespace = namespace
        self.properties = properties
        self.anchor = anchor
        self.isSource = isSource
    }
}

// MARK: - Hashable

extension GeometryEffectPropertiesModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(namespace)
        hasher.combine(properties.rawValue)
        hasher.combine(anchor.x)
        hasher.combine(anchor.y)
        hasher.combine(isSource)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.namespace == rhs.namespace
            && lhs.properties == rhs.properties
            && lhs.anchor == rhs.anchor
            && lhs.isSource == rhs.isSource
    }
}
