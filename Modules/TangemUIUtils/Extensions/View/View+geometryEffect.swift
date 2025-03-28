//
//  View+geometryEffect.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func matchedGeometryEffectOptional<ID>(
        id: ID?,
        in namespace: Namespace.ID?,
        properties: MatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center,
        isSource: Bool = true
    ) -> some View where ID: Hashable {
        if let id, let namespace {
            matchedGeometryEffect(id: id, in: namespace, properties: properties, anchor: anchor, isSource: isSource)
        } else if id == nil, namespace == nil {
            self
        } else {
            let _ = assertionFailure("You must set either both ID and namespace or neither")
            self
        }
    }

    @ViewBuilder
    func matchedGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> some View {
        if let effect {
            matchedGeometryEffect(id: effect.id, in: effect.namespace, isSource: effect.isSource)
        } else {
            self
        }
    }
}
