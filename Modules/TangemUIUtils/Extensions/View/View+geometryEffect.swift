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
    func matchedGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> some View {
        if let effect {
            matchedGeometryEffect(id: effect.id, in: effect.namespace, isSource: effect.isSource)
        } else {
            self
        }
    }
}
