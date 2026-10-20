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

    @ViewBuilder
    private var header: some View {
        if let model {
            if let title = model.title {
                headerRow(title: title)
            }
        } else {
            headerRow(title: nil)
        }
    }

    private func headerRow(title: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(Constants.titleLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
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

    private var showsHeader: Bool {
        model.map { $0.title != nil } ?? true
    }

    @ViewBuilder
    private var meta: some View {
        if let model {
            HStack(spacing: Constants.metaSpacing) {
                if model.category != nil || model.volumeText != nil {
                    PolymarketMarketMetaRow(
                        category: model.category,
                        volume: model.volumeText.map {
                            .init(title: Localization.predictionDetailsMarketVolume, value: $0)
                        }
                    )
                }

                if let predictedText = model.predictedText {
                    Text(predictedText)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusSuccess)
                        .lineLimit(1)
                        .padding(.horizontal, Constants.predictedPadding)
                        .frame(minHeight: Constants.predictedMinHeight)
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
                        label(for: outcome)
                    }
                    .buttonStyle(.plain)
                    .disabled(!outcome.isEnabled)
                    .opacity(outcome.isEnabled ? 1 : Constants.disabledOutcomeOpacity)
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
        .padding(.top, showsHeader ? Constants.buttonsTopPadding : 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func label(for outcome: Outcome) -> some View {
        HStack(spacing: Constants.labelSpacing) {
            Text(outcome.title)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(Constants.priceSeparator + outcome.priceText)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
        }
        .style(DesignSystem.Font.bodyMediumToken, color: outcome.style.foregroundColor)
        .padding(.horizontal, Constants.labelHorizontalPadding)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
        .background(outcome.style.backgroundColor, in: Capsule())
    }

    private var avatar: some View {
        PolymarketAvatarView(url: model?.imageURL, isLoading: model == nil)
    }
}

// MARK: - Constants

private extension PolymarketMarketCard {
    enum Constants {
        static let labelSpacing: CGFloat = 4
        static let titleLineLimit = 2
        static let disabledOutcomeOpacity: CGFloat = 0.4
        static let labelHorizontalPadding: CGFloat = 8
        static let priceSeparator = String.bulletSign + " "
        static let metaSpacing: CGFloat = 4
        static let buttonsTopPadding: CGFloat = 8
        static let predictedPadding: CGFloat = 4
        static let predictedMinHeight: CGFloat = 16
    }
}
