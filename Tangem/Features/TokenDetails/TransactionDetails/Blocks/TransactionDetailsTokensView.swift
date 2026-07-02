//
//  TransactionDetailsTokensView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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
        let direction: String
        let tokenIconInfo: TokenIconInfo
        let amountText: String
        let fiatText: String?
    }
}

struct TransactionDetailsTokensView: View {
    let data: TransactionDetailsTokensViewData

    @ScaledMetric private var tokenSide: CGFloat = 72
    @ScaledMetric private var legTokenSide: CGFloat = 40

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
        VStack(spacing: 8) {
            legRow(from)

            DashedDivider(color: DesignSystem.Color.borderSecondary)
                .padding(.horizontal, 12)

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
        VStack(alignment: .leading, spacing: .zero) {
            Text(leg.direction)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .padding(.top, 12)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(leg.amountText)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let fiatText = leg.fiatText {
                        Text(fiatText)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                TokenIcon(tokenIconInfo: leg.tokenIconInfo, size: CGSize(bothDimensions: legTokenSide))
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
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
    func previewTokenIconInfo(_ name: String, color: Color?) -> TokenIconInfo {
        TokenIconInfo(name: name, blockchainIconAsset: nil, imageURL: nil, isCustom: false, customTokenColor: color)
    }

    return VStack(spacing: 32) {
        // Single (transfer / stake)
        TransactionDetailsTokensView(data: .init(
            tokenIconInfo: previewTokenIconInfo("Tether", color: .green),
            amountText: "+350.31 USDT",
            fiatText: "$350.31"
        ))

        // Pair (swap / onramp)
        TransactionDetailsTokensView(
            data: .init(
                from: .init(
                    direction: "From",
                    tokenIconInfo: previewTokenIconInfo("Tether", color: .green),
                    amountText: "− 390 USDT",
                    fiatText: "$391.12"
                ),
                to: .init(
                    direction: "To",
                    tokenIconInfo: previewTokenIconInfo("Polygon", color: .purple),
                    amountText: "~ 1,800.00 POL",
                    fiatText: "$391.12"
                )
            )
        )
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
