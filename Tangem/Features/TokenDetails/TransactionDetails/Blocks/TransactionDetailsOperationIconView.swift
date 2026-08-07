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
    let containerSize: CGFloat
    let glyphSize: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(backgroundColor)

            data.icon
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(size: CGSize(bothDimensions: glyphSize))
                .foregroundStyle(glyphColor)
        }
        .frame(size: CGSize(bothDimensions: containerSize))
    }

    private var backgroundColor: Color {
        switch data.status {
        case .failed, .undefined: DesignSystem.Color.bgStatusErrorSubtle
        case .inProgress: DesignSystem.Color.bgStatusInfoSubtle
        case .confirmed: DesignSystem.Color.bgSecondary
        }
    }

    private var glyphColor: Color {
        switch data.status {
        case .failed, .undefined: DesignSystem.Color.iconStatusError
        case .inProgress: DesignSystem.Color.iconStatusInfo
        case .confirmed: DesignSystem.Color.iconSecondary
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
    let statuses: [(String, TransactionViewModel.Status)] = [
        ("confirmed", .confirmed),
        ("inProgress", .inProgress),
        ("failed", .failed),
    ]

    return VStack(alignment: .leading, spacing: 16) {
        ForEach(statuses, id: \.0) { statusName, status in
            Text(statusName).style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            HStack(spacing: 16) {
                ForEach(types, id: \.0) { _, type, isOutgoing in
                    TransactionDetailsOperationIconView(
                        data: .init(type: type, status: status, isOutgoing: isOutgoing),
                        containerSize: 36,
                        glyphSize: 18
                    )
                }
            }
        }

        Text("badge size (24)").style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        TransactionDetailsOperationIconView(
            data: .init(type: .transfer, status: .confirmed, isOutgoing: false),
            containerSize: 24,
            glyphSize: 12
        )
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
