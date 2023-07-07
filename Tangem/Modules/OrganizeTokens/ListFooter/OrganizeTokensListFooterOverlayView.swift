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
            colors: [Colors.Background.fadeStart, Colors.Background.fadeEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .frame(height: 100.0)
        .infinityFrame(alignment: .bottom)
    }
}
