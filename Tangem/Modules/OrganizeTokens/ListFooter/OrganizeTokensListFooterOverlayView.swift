//
//  OrganizeTokensListFooterOverlayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListFooterOverlayView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Colors.Background.primary.opacity(0.0),
                Colors.Background.primary.opacity(0.9),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .infinityFrame(alignment: .top)
        .ignoresSafeArea(edges: .bottom)
    }
}
