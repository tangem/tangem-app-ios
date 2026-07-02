//
//  TransactionDetailsTokensView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI
import TangemUIUtils

struct TransactionDetailsTokensViewData: Equatable {
    enum Content: Equatable {
        /// Transfer, stake, onramp single-icon.
        case single(Single)
        /// Swap, onramp.
        case pair(from: Leg, to: Leg)
    }

    let content: Content

    /// Transfer / stake
    init(
        tokenIconInfo: TokenIconInfo,
        amountText: String,
        fiatText: String? = nil
    ) {
        content = .single(Single(
            tokenIconInfo: tokenIconInfo,
            amountText: amountText,
            fiatText: fiatText
        ))
    }

    /// Swap / onramp
    init(from: Leg, to: Leg) {
        content = .pair(from: from, to: to)
    }

    struct Single: Equatable {
        let tokenIconInfo: TokenIconInfo
        let amountText: String
        let fiatText: String?
    }

    struct Leg: Equatable {
        enum Icon: Equatable {
            case token(TokenIconInfo)
            case image(url: URL?)
        }

        struct Direction: Equatable {
            let label: String
            let actor: TransactionDetailsActor?
        }

        let direction: Direction
        let icon: Icon
        let amountText: String
        let fiatText: String?
        let isAmountStrikethrough: Bool

        init(
            direction: Direction,
            icon: Icon,
            amountText: String,
            fiatText: String?,
            isAmountStrikethrough: Bool = false
        ) {
            self.direction = direction
            self.icon = icon
            self.amountText = amountText
            self.fiatText = fiatText
            self.isAmountStrikethrough = isAmountStrikethrough
        }
    }
}

struct TransactionDetailsTokensView: View {
    let data: TransactionDetailsTokensViewData

    @ScaledMetric private var tokenSide: CGFloat = 72
    @ScaledMetric private var legTokenSide: CGFloat = 40
    @ScaledMetric private var captionIconSide: CGFloat = 18

    var body: some View {
        switch data.content {
        case .single(let single):
            singleView(single)
        case .pair(let from, let to):
            pairCard(from: from, to: to)
        }
    }

    // MARK: - Single

    private func singleView(_ single: TransactionDetailsTokensViewData.Single) -> some View {
        VStack(spacing: 24) {
            TokenIcon(tokenIconInfo: single.tokenIconInfo, size: CGSize(bothDimensions: tokenSide))

            VStack(spacing: 2) {
                Text(single.amountText)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let fiatText = single.fiatText {
                    Text(fiatText)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Pair

    private func pairCard(from: TransactionDetailsTokensViewData.Leg, to: TransactionDetailsTokensViewData.Leg) -> some View {
        VStack(spacing: 4) {
            legRow(from)

            DashedDivider(color: DesignSystem.Color.borderSecondary)
                .padding(.horizontal, 16)

            legRow(to)
        }
        .padding(.vertical, 4)
        .background(
            DesignSystem.Color.bgTertiary,
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay { flowArrow }
    }

    private func legRow(_ leg: TransactionDetailsTokensViewData.Leg) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                directionCaption(leg.direction)

                VStack(alignment: .leading, spacing: 2) {
                    Text(leg.amountText)
                        .style(
                            DesignSystem.Font.headingSmallToken,
                            color: leg.isAmountStrikethrough ? DesignSystem.Color.textTertiary : DesignSystem.Color.textPrimary
                        )
                        .strikethrough(leg.isAmountStrikethrough)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let fiatText = leg.fiatText {
                        Text(fiatText)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)

            legIcon(leg.icon)
                .frame(size: CGSize(bothDimensions: legTokenSide))
        }
        .padding(16)
    }

    @ViewBuilder
    private func directionCaption(_ direction: TransactionDetailsTokensViewData.Leg.Direction) -> some View {
        HStack(spacing: 4) {
            Text(direction.label)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if let actor = direction.actor {
                actorIcon(actor)

                Text(actor.displayName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func actorIcon(_ actor: TransactionDetailsActor) -> some View {
        switch actor {
        case .address(_, let blockiesImage):
            AddressBlockiesIconView(viewData: blockiesImage, size: captionIconSide)
        case .contact(_, let icon):
            AddressBookContactNameIconView(viewData: icon, size: captionIconSide)
        case .account(_, let icon), .accountInWallet(_, let icon, _):
            AccountIconView(data: icon, settings: .smallSized)
        case .wallet:
            EmptyView()
        }
    }

    @ViewBuilder
    private func legIcon(_ icon: TransactionDetailsTokensViewData.Leg.Icon) -> some View {
        switch icon {
        case .token(let tokenIconInfo):
            TokenIcon(tokenIconInfo: tokenIconInfo, size: CGSize(bothDimensions: legTokenSide))
        case .image(let url):
            IconView(url: url, size: CGSize(bothDimensions: legTokenSide))
                .clipShape(.circle)
        }
    }

    private var flowArrow: some View {
        DesignSystem.Icons.ArrowDown.regular16.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: 16))
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .padding(4)
            .background(DesignSystem.Color.bgTertiary)
    }
}

// MARK: - Dashed divider

private struct DashedDivider: View {
    let color: Color

    var body: some View {
        Line()
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

// MARK: - Previews

#Preview("Tokens") {
    VStack(spacing: 32) {
        // Single (transfer / stake)
        TransactionDetailsTokensView(data: TransactionDetailsPreviewFactory.tokensSingle())

        // Pair (swap / onramp)
        TransactionDetailsTokensView(data: TransactionDetailsPreviewFactory.tokensPair())
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
