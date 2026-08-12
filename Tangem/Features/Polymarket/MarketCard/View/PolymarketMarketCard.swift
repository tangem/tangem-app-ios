//
//  PolymarketMarketCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct PolymarketMarketCard: View {
    private let model: Model

    init(model: Model) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            buttons
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                meta
            }

            avatar
        }
        .padding(16)
    }

    private var meta: some View {
        HStack(spacing: 4) {
            if let volumeText = model.volumeText {
                HStack(spacing: 2) {
                    // [REDACTED_TODO_COMMENT]
                    Text("Volume: ").foregroundStyle(DesignSystem.Color.textSecondary)
                    Text(volumeText).foregroundStyle(DesignSystem.Color.textPrimary)
                }
                .font(token: DesignSystem.Font.captionMediumToken)
                .lineLimit(1)
            }

            if let predictedText = model.predictedText {
                Text(predictedText)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusSuccess)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .frame(minHeight: 16)
                    .background(DesignSystem.Color.bgStatusSuccessSubtle, in: Capsule())
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 4) {
            ForEach(model.outcomes) { outcome in
                Button(action: outcome.onSelect) {
                    Text("\(outcome.title) • \(outcome.priceText)")
                        .style(DesignSystem.Font.bodyMediumToken, color: outcome.style.foregroundColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(outcome.style.backgroundColor, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(outcome.title) \(outcome.priceText)")
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var avatar: some View {
        Group {
            if let url = model.imageURL {
                KFImage(url)
                    .cancelOnDisappear(true)
                    .placeholder { Shimmer().clipShape(.circle) }
                    .resizable()
                    .scaledToFill()
            } else {
                DesignSystem.Color.bgOpaquePrimary
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay { Circle().stroke(DesignSystem.Color.borderPrimary, lineWidth: 1) }
        .accessibilityHidden(true)
    }
}

private extension PolymarketMarketCard.Outcome.Style {
    var backgroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.bgStatusInfoSubtle
        case .negative: DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    var foregroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.textBrand
        case .negative: DesignSystem.Color.textStatusError
        }
    }
}
