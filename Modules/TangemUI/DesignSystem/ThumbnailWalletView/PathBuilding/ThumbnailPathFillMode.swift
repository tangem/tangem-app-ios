//
//  ThumbnailPathFillMode.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum ThumbnailPathFillMode {
    case fill(
        path: Path,
        fillColor: Color,
        stroke: Stroke? = nil
    )
    case subtracting(
        origin: Path,
        subtracting: Path,
        fillColor: Color,
        stroke: Stroke? = nil
    )

    struct Stroke {
        let color: Color
        let style: StrokeStyle
    }
}
