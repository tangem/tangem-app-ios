//
//  ForYouEntranceBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils
import TangemLocalization

struct ForYouEntranceBannerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: .unit(.x3)) {
            icon
            titleAndDescription
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.unit(.x4))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .angularGlowBorder(config: .magic)
        .clipShape(RoundedRectangle(cornerRadius: .unit(.x6), style: .continuous))
    }
}

private extension ForYouEntranceBannerView {
    var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: .unit(.x1)) {
            Text(Localization.forYouTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.forYouDescription)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    var icon: some View {
        Assets.ForYou.pieChart.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }

    var background: some View {
        RoundedRectangle(cornerRadius: .unit(.x6), style: .continuous)
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: .unit(.x6), style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            )
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()
        ForYouEntranceBannerView()
            .padding(.horizontal, .unit(.x4))
    }
}
#endif // DEBUG
