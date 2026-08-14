//
//  TangemPayCashbackDetailSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TangemPayCashbackDetailSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            summaryCards

            chartSection

            transactionsSection

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sections

private extension TangemPayCashbackDetailSkeletonView {
    var header: some View {
        VStack(spacing: 8) {
            Shimmer().variant(.custom(width: 236, height: 30, cornerRadius: 8))
            Shimmer().variant(.custom(width: 100, height: 12, cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 48)
    }

    var summaryCards: some View {
        HStack(spacing: 8) {
            Shimmer().variant(.custom(height: 132, cornerRadius: 24))
            Shimmer().variant(.custom(height: 132, cornerRadius: 24))
        }
        .padding(.bottom, 16)
    }

    var chartSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Shimmer().variant(.custom(width: 200, height: 24, cornerRadius: 16))
                .padding(.vertical, 16)

            Color.clear
                .frame(height: 160)

            monthsAxis
        }
        .padding(.bottom, 48)
    }

    var monthsAxis: some View {
        HStack(spacing: 16) {
            ForEach(recentMonths, id: \.self) { month in
                VStack(alignment: .center, spacing: 8) {
                    Shimmer().variant(.custom(height: 2, cornerRadius: 2))

                    Text(month)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Shimmer().variant(.custom(width: 200, height: 20, cornerRadius: 16))
            Shimmer().variant(.custom(height: 110, cornerRadius: 24))
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Helpers

private extension TangemPayCashbackDetailSkeletonView {
    var recentMonths: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let calendar = Calendar.current
        let now = Date()

        return (0 ..< 5)
            .reversed()
            .compactMap { offset in
                calendar
                    .date(byAdding: .month, value: -offset, to: now)
                    .map(formatter.string(from:))
            }
    }
}

// MARK: - Previews

#Preview {
    TangemPayCashbackDetailSkeletonView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
