//
//  TransactionDetailsHeaderView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TransactionDetailsHeaderViewData: Equatable {
    enum TitleStyle: Equatable {
        /// Active / in-progress.
        case active
        /// Verification required / paused.
        case attention
        /// Successful terminal status.
        case neutral
        /// Failed / refunded terminal status.
        case failed
        /// Expired terminal status.
        case expired
    }

    let title: String
    let titleStyle: TitleStyle
    let date: String
    let operationIcon: TransactionViewIconViewData
    let iconGlyph: ImageType?
    let menuActions: [MenuAction]

    struct MenuAction: Identifiable, Equatable {
        let id: String
        let title: String
        let icon: ImageType?
        let action: TransactionDetailsViewModel.ViewAction
    }
}

struct TransactionDetailsHeaderView: View {
    let data: TransactionDetailsHeaderViewData
    let onAction: (TransactionDetailsViewModel.ViewAction) -> Void

    @ScaledMetric private var iconSide: CGFloat = 44
    @ScaledMetric private var glyphSide: CGFloat = 20

    var body: some View {
        HStack(spacing: 12) {
            TransactionDetailsOperationIconView(
                data: data.operationIcon,
                titleStyle: data.titleStyle,
                glyphOverride: data.iconGlyph,
                containerSize: iconSide,
                glyphSize: glyphSide
            )

            VStack(alignment: .leading, spacing: 4) {
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

                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: { onAction(.close) }
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var titleColor: Color {
        switch data.titleStyle {
        case .active: DesignSystem.Color.textBrand
        case .attention: DesignSystem.Color.textStatusWarning
        case .neutral: DesignSystem.Color.textPrimary
        case .failed: DesignSystem.Color.textStatusError
        case .expired: DesignSystem.Color.textTertiary
        }
    }

    private var menuButton: some View {
        Menu {
            ForEach(data.menuActions) { menuAction in
                Button(action: { onAction(menuAction.action) }) {
                    if let icon = menuAction.icon {
                        Label(
                            title: { Text(menuAction.title) },
                            icon: { icon.image.renderingMode(.template) }
                        )
                    } else {
                        Text(menuAction.title)
                    }
                }
            }
        } label: {
            TangemUI.Button(
                icon: DesignSystem.Icons.DotsHorizontal.regular20,
                accessibilityLabel: Localization.commonMore,
                action: {}
            )
            .size(.x11)
            .styleType(.material(.glass))
            .allowsHitTesting(false)
        }
        .buttonStyle(.plain)
        .menuOrder(.fixed)
    }
}

// MARK: - Previews

#Preview("Header states") {
    let menu: [TransactionDetailsHeaderViewData.MenuAction] = [
        // [REDACTED_TODO_COMMENT]
        .init(id: "explore", title: "Explore", icon: Assets.Glyphs.explore, action: .close),
    ]

    return VStack(spacing: 32) {
        // In progress — brand (blue) title, with menu.
        TransactionDetailsHeaderView(
            data: .init(title: "Receiving", titleStyle: .active, date: "Jan 20 2026, 9:24 PM", operationIcon: .init(type: .transfer, status: .inProgress, isOutgoing: false), iconGlyph: nil, menuActions: menu),
            onAction: { _ in }
        )
        // Confirmed — primary title, with menu.
        TransactionDetailsHeaderView(
            data: .init(title: "Received", titleStyle: .neutral, date: "Jan 20 2026, 9:24 PM", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: false), iconGlyph: nil, menuActions: menu),
            onAction: { _ in }
        )
        // Failed — red title, no menu (close only).
        TransactionDetailsHeaderView(
            data: .init(title: "Send failed", titleStyle: .failed, date: "Jan 20 2026, 9:24 PM", operationIcon: .init(type: .transfer, status: .failed, isOutgoing: true), iconGlyph: nil, menuActions: []),
            onAction: { _ in }
        )
    }
    .background(DesignSystem.Color.bgSecondary)
}
