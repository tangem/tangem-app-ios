//
//  LoadingSingleWalletMainContentRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct LoadingSingleWalletMainContentRedesignedView: View {
    var body: some View {
        VStack(spacing: .unit(.x2)) {
            RedesignedAccountSkeletonCardView()
        }
        .padding(.horizontal, .unit(.x3))
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZStack {
        Color.Tangem.Surface.level2
            .ignoresSafeArea()

        LoadingSingleWalletMainContentRedesignedView()
    }
}
#endif // DEBUG
