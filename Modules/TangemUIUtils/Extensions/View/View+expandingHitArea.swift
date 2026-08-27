//
//  View+expandingHitArea.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func expandingHitArea(_ edges: Edge.Set = .all, by inset: CGFloat) -> some View {
        padding(edges, inset)
            .contentShape(.rect)
            .padding(edges, -inset)
    }
}
