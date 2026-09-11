//
//  PolymarketEventCardSkeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PolymarketEventCardSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            header
            marketRow
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                bar(width: 160, height: 16)
                bar(width: 128, height: 16)

                HStack(spacing: 8) {
                    bar(width: 40, height: 12)
                    bar(width: 72, height: 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Shimmer()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
        .padding(16)
    }

    private var marketRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                bar(width: 168, height: 16)
                bar(width: 88, height: 12)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview {
    PolymarketEventCardSkeleton()
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
