//
//  LoadingSingleWalletMainContentRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct LoadingSingleWalletMainContentRedesignedView: View {
    var body: some View {
        VStack(spacing: 8) {
            RedesignedAccountSkeletonCardView()
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary
            .ignoresSafeArea()

        LoadingSingleWalletMainContentRedesignedView()
    }
}
#endif // DEBUG
