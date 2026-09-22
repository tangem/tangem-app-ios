//
//  WithdrawHubActionTileView+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension WithdrawHubActionTileView {
    struct Skeleton: View {
        var body: some View {
            Shimmer()
                .variant(.custom(cornerRadius: Constants.cornerRadius))
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        HStack(spacing: 8) {
            WithdrawHubActionTileView.Skeleton()
            WithdrawHubActionTileView.Skeleton()
        }
        .frame(width: 332, height: 136)
        .padding(.horizontal, 16)
    }
}
