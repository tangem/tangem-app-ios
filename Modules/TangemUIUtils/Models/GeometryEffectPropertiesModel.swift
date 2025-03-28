//
//  GeometryEffect.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public struct GeometryEffectPropertiesModel: Hashable {
    let id: String
    let namespace: Namespace.ID
    let isSource: Bool

    public init(id: String, namespace: Namespace.ID, isSource: Bool = true) {
        self.id = id
        self.namespace = namespace
        self.isSource = isSource
    }
}
