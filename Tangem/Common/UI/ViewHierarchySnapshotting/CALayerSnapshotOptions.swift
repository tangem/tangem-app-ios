//
//  CALayerSnapshotOptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum CALayerSnapshotOptions {
    /// The `CALayer` instance itself.
    case `default`
    /// Uses `CALayer.model()`.
    case model
    /// Uses `CALayer.presentation()`.
    case presentation
}
