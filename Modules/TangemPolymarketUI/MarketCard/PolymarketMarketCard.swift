//
//  PolymarketMarketCard.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketMarketCard: View {
    public static var skeleton: Self { Self(model: nil) }

    private let model: Model?

    public init(model: Model) {
        self.model = model
    }

    private init(model: Model?) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            if model.map(\.outcomes.isNotEmpty) ?? true {
                buttons
            }
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let model {
                    Text(model.title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Shimmer().variant(.text(style: .body))
                }

                meta
            }

            avatar
        }
        .padding(16)
    }

    @ViewBuilder
    private var meta: some View {
        if let model {
            HStack(spacing: 4) {
                if let volumeText = model.volumeText {
                    HStack(spacing: 2) {
                        Text(Localization.predictionDetailsMarketVolume).foregroundStyle(DesignSystem.Color.textSecondary)
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
        } else {
            Shimmer().variant(.text(style: .caption))
        }
    }

    private var buttons: some View {
        HStack(spacing: 4) {
            if let model {
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
            } else {
                ForEach(0 ..< 2, id: \.self) { _ in
                    Shimmer()
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var avatar: some View {
        PolymarketAvatarView(url: model?.imageURL, isLoading: model == nil)
    }
}
