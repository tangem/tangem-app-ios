//
//  TransactionDetailsHeaderView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation

struct TransactionDetailsHeaderViewData: Equatable {
    let title: String
    let date: String
    let operationIcon: TransactionViewIconViewData
    let menuActions: [MenuAction]
    @IgnoredEquatable var onClose: () -> Void

    struct MenuAction: Identifiable, Equatable {
        let id: String
        let title: String
        let icon: ImageType?
        @IgnoredEquatable var handler: () -> Void
    }
}

struct TransactionDetailsHeaderView: View {
    let data: TransactionDetailsHeaderViewData

    @ScaledMetric private var iconSide: CGFloat = 36

    var body: some View {
        HStack(spacing: 12) {
            TransactionDetailsOperationIconView(
                data: data.operationIcon,
                containerSize: iconSide,
                glyphSize: iconSide * 0.5
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: titleColor)
                    .lineLimit(1)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: data.title)

                Text(data.date)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                if !data.menuActions.isEmpty {
                    menuButton
                }

                CircleButton(image: DesignSystem.Icons.Cross.regular20, action: data.onClose)
                    .size(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var titleColor: Color {
        switch data.operationIcon.status {
        case .inProgress: DesignSystem.Color.textBrand
        case .failed, .undefined: DesignSystem.Color.textStatusError
        case .confirmed: DesignSystem.Color.textPrimary
        }
    }

    private var menuButton: some View {
        Menu {
            ForEach(data.menuActions) { action in
                Button(action: action.handler) {
                    if let icon = action.icon {
                        Label(
                            title: { Text(action.title) },
                            icon: { icon.image }
                        )
                    } else {
                        Text(action.title)
                    }
                }
            }
        } label: {
            DesignSystem.Icons.DotsHorizontal.regular20.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(size: CGSize(bothDimensions: 20))
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .padding(8)
                .background(Circle().fill(DesignSystem.Color.bgTertiary))
                .contentShape(.circle)
        }
    }
}

// MARK: - Previews

#Preview("Header states") {
    let menu: [TransactionDetailsHeaderViewData.MenuAction] = [
        // [REDACTED_TODO_COMMENT]
        .init(id: "explore", title: "Explore", icon: Assets.Glyphs.explore, handler: {}),
    ]

    return VStack(spacing: 32) {
        // In progress — brand (blue) title, with menu.
        TransactionDetailsHeaderView(
            data: .init(title: "Receiving", date: "Jan 20 2026, 9:24 PM", operationIcon: .init(type: .transfer, status: .inProgress, isOutgoing: false), menuActions: menu, onClose: {})
        )
        // Confirmed — primary title, with menu.
        TransactionDetailsHeaderView(
            data: .init(title: "Received", date: "Jan 20 2026, 9:24 PM", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: false), menuActions: menu, onClose: {})
        )
        // Failed — primary title, no menu (close only).
        TransactionDetailsHeaderView(
            data: .init(title: "Sending failed", date: "Jan 20 2026, 9:24 PM", operationIcon: .init(type: .transfer, status: .failed, isOutgoing: true), menuActions: [], onClose: {})
        )
    }
    .background(DesignSystem.Color.bgSecondary)
}
