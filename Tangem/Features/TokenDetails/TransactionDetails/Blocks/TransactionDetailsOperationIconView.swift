//
//  TransactionDetailsOperationIconView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TransactionDetailsOperationIconView: View {
    let data: TransactionViewIconViewData
    let titleStyle: TransactionDetailsHeaderViewData.TitleStyle
    let glyphOverride: ImageType?
    let containerSize: CGFloat
    let glyphSize: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(backgroundColor)

            glyph
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(size: CGSize(bothDimensions: glyphSize))
                .foregroundStyle(glyphColor)
        }
        .frame(size: CGSize(bothDimensions: containerSize))
    }

    private var glyph: Image {
        glyphOverride?.image ?? data.icon
    }

    private var backgroundColor: Color {
        switch titleStyle {
        case .active: DesignSystem.Color.bgStatusInfoSubtle
        case .attention: DesignSystem.Color.bgStatusWarningSubtle
        case .neutral: DesignSystem.Color.bgOpaqueSecondary
        case .failed: DesignSystem.Color.bgStatusErrorSubtle
        case .expired: DesignSystem.Color.bgOpaqueSecondary
        }
    }

    private var glyphColor: Color {
        switch titleStyle {
        case .active: DesignSystem.Color.iconStatusInfo
        case .attention: DesignSystem.Color.iconStatusWarning
        case .neutral: DesignSystem.Color.iconPrimary
        case .failed: DesignSystem.Color.iconStatusError
        case .expired: DesignSystem.Color.iconTertiary
        }
    }
}

// MARK: - Previews

#Preview("Operation icon") {
    let types: [(String, TransactionViewModel.TransactionType, Bool)] = [
        ("Send", .transfer, true),
        ("Receive", .transfer, false),
        ("Swap", .swap, true),
        ("Stake", .stake, true),
        ("Approve", .approve, true),
    ]
    let styles: [(String, TransactionDetailsHeaderViewData.TitleStyle)] = [
        ("active", .active),
        ("attention", .attention),
        ("neutral", .neutral),
        ("failed", .failed),
        ("expired", .expired),
    ]

    return VStack(alignment: .leading, spacing: 16) {
        ForEach(styles, id: \.0) { styleName, style in
            Text(styleName).style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            HStack(spacing: 16) {
                ForEach(types, id: \.0) { _, type, isOutgoing in
                    TransactionDetailsOperationIconView(
                        data: .init(type: type, status: .inProgress, isOutgoing: isOutgoing),
                        titleStyle: style,
                        glyphOverride: nil,
                        containerSize: 36,
                        glyphSize: 18
                    )
                }
            }
        }

        Text("badge size (24)").style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        TransactionDetailsOperationIconView(
            data: .init(type: .transfer, status: .confirmed, isOutgoing: false),
            titleStyle: .neutral,
            glyphOverride: nil,
            containerSize: 24,
            glyphSize: 12
        )
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
