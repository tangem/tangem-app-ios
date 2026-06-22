//
//  TransactionViewRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

struct TransactionViewRedesigned: View {
    let viewModel: TransactionViewModel

    @ScaledMetric private var iconContainerSide: CGFloat = 40
    @ScaledMetric private var glyphSize: CGFloat = 20
    @ScaledMetric private var iconBorderWidth: CGFloat = 1

    private var display: TransactionDisplayModel { viewModel.display }

    var body: some View {
        TangemTwoLineRowLayout(
            icon: { iconView },
            primaryLeading: { nameView },
            primaryTrailing: { amountView },
            secondaryLeading: { subtitleView },
            secondaryTrailing: { currencyView }
        )
        .compressionPolicy(.trailingPreserved)
    }

    private var iconView: some View {
        ZStack {
            Circle().fill(iconBackgroundColor)

            iconContent
        }
        .frame(width: iconContainerSide, height: iconContainerSide)
    }

    @ViewBuilder
    private var iconContent: some View {
        if case .tangemPay(.spend(_, let iconURL?, _, _)) = viewModel.transactionType {
            KFImage(iconURL)
                .resizable()
                .placeholder { glyphImage }
                .aspectRatio(contentMode: .fit)
                .frame(width: iconContainerSide, height: iconContainerSide)
                .clipShape(Circle())
        } else {
            glyphImage
        }
    }

    private var glyphImage: some View {
        viewModel.icon.icon
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: glyphSize, height: glyphSize)
            .foregroundStyle(iconGlyphColor)
    }

    private var nameView: some View {
        HStack(spacing: .unit(.x2)) {
            Text(display.title)
                .style(Font.Tangem.Body16.medium, color: nameColor)
                .lineLimit(1)

            if viewModel.inProgress {
                ProgressDots(style: .small)
            }
        }
    }

    private var amountView: some View {
        SensitiveText(viewModel.amount.value)
            .style(Font.Tangem.Body16.medium, color: amountColor)
            .strikethrough(isFailed, color: amountColor)
            .lineLimit(1)
            .layoutPriority(1)
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch display.subtitle {
        case .owner(let direction, let owner):
            TransactionSubtitleView(direction: direction, owner: owner)

        case .text(let description):
            Text(description)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                .lineLimit(1)
                .truncationMode(viewModel.transactionDescriptionTruncationMode)

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var currencyView: some View {
        if viewModel.amount.currencyCode.isNotEmpty {
            Text(viewModel.amount.currencyCode)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Status-driven styling

private extension TransactionViewRedesigned {
    var isFailed: Bool { viewModel.icon.status == .failed }

    var nameColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Text.Status.warning
        case .inProgress: .Tangem.Text.Status.accent
        case .confirmed: .Tangem.Text.Neutral.primary
        }
    }

    var amountColor: Color {
        if let tangemPayAmountColor {
            return tangemPayAmountColor
        }

        switch viewModel.icon.status {
        case .failed, .undefined, .inProgress: return .Tangem.Text.Neutral.tertiary
        case .confirmed: return .Tangem.Text.Neutral.primary
        }
    }

    var tangemPayAmountColor: Color? {
        guard case .tangemPay(let payType) = viewModel.transactionType else { return nil }

        switch payType {
        case .spend(_, _, let isDeclined, _) where isDeclined:
            return .Tangem.Text.Status.warning
        case .spend(_, _, _, let isNegativeAmount) where isNegativeAmount:
            return .Tangem.Text.Status.accent
        case .transfer where !viewModel.isOutgoing:
            return .Tangem.Text.Status.accent
        case .spend, .transfer, .fee:
            return nil
        }
    }

    var iconBackgroundColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Markers.backgroundTintedRed
        case .inProgress: .Tangem.Markers.backgroundTintedBlue
        case .confirmed: .Tangem.Markers.backgroundTintedGray
        }
    }

    var iconGlyphColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Markers.iconRed
        case .inProgress: .Tangem.Markers.iconBlue
        case .confirmed: .Tangem.Graphic.Neutral.secondary
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("States") {
    VStack(spacing: 16) {
        TransactionViewRedesigned(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "−350.31 USDT",
                value: "−350.31",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .transfer,
                status: .confirmed,
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "+350.31 USDT",
                value: "+350.31",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .transfer,
                status: .inProgress,
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "350.31 USDT",
                value: "350.31",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .transfer,
                status: .failed,
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .contract("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "+350.00 USDT",
                value: "+350.00",
                currencyCode: "USDT",
                isOutgoing: false,
                transactionType: .swap,
                status: .confirmed,
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .contract("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "+350.00 USDT",
                value: "+350.00",
                currencyCode: "USDT",
                isOutgoing: false,
                transactionType: .swap,
                status: .inProgress,
                isFromYieldContract: false
            )
        )
    }
    .padding()
    .background(Colors.Background.secondary)
}

#endif // DEBUG
