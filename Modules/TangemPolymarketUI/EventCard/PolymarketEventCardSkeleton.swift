//
//  PolymarketEventCardSkeleton.swift
//  TangemPolymarketUI
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
            rowDivider
            marketRow
            outcomesBadge
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Shimmer().variant(.text(style: .body))
                    Shimmer().variant(.text(style: .body))
                }

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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                bar(width: 168, height: 16)
                bar(width: 88, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                bar(width: 56, height: 36)
                bar(width: 56, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        DesignSystem.Color.borderPrimary
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private var outcomesBadge: some View {
        bar(width: 104, height: 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
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
