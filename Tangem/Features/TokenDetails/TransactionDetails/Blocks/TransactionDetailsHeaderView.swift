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

    /// How the line under the title reads. A sent transaction states when it happened, which is a neutral fact;
    /// an operation still waiting on its co-signers states that instead, and the colour is what carries it.
    enum SubtitleStyle: Equatable {
        case secondary
        case warning
    }

    let title: String
    let titleStyle: TitleStyle
    let date: String
    let subtitleStyle: SubtitleStyle
    let operationIcon: TransactionViewIconViewData
    let iconGlyph: ImageType?
    let menuSections: [MenuSection]

    struct MenuSection: Identifiable, Equatable {
        let id: String
        let actions: [MenuAction]
    }

    struct MenuAction: Identifiable, Equatable {
        let id: String
        let title: String
        let icon: ImageType?
        let action: TransactionDetailsViewModel.ViewAction
        var role: ButtonRole?
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
                    .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                if !data.menuSections.isEmpty {
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
        case .failed, .expired: DesignSystem.Color.textStatusError
        }
    }

    private var subtitleColor: Color {
        switch data.subtitleStyle {
        case .secondary: DesignSystem.Color.textSecondary
        case .warning: DesignSystem.Color.textStatusWarning
        }
    }

    private var menuButton: some View {
        Menu {
            ForEach(data.menuSections) { section in
                Section {
                    ForEach(section.actions) { menuAction in
                        Button(role: menuAction.role, action: { onAction(menuAction.action) }) {
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
    let menu: [TransactionDetailsHeaderViewData.MenuSection] = [
        .init(id: "address", actions: [
            .init(id: "copyAddress", title: "Copy address", icon: DesignSystem.Icons.Copy.regular24, action: .close),
            .init(id: "addContact", title: "Add contact", icon: DesignSystem.Icons.UserPlus.regular24, action: .close),
        ]),
        .init(id: "transaction", actions: [
            .init(id: "explore", title: "Explore", icon: DesignSystem.Icons.Globe.regular24, action: .close),
        ]),
    ]

    return VStack(spacing: 32) {
        // In progress — brand (blue) title, with menu.
        TransactionDetailsHeaderView(
            data: .init(title: "Receiving", titleStyle: .active, date: "Jan 20 2026, 9:24 PM", subtitleStyle: .secondary, operationIcon: .init(type: .transfer, status: .inProgress, isOutgoing: false), iconGlyph: nil, menuSections: menu),
            onAction: { _ in }
        )
        // Confirmed — primary title, with menu.
        TransactionDetailsHeaderView(
            data: .init(title: "Received", titleStyle: .neutral, date: "Jan 20 2026, 9:24 PM", subtitleStyle: .secondary, operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: false), iconGlyph: nil, menuSections: menu),
            onAction: { _ in }
        )
        // Failed — red title, no menu (close only).
        TransactionDetailsHeaderView(
            data: .init(title: "Send failed", titleStyle: .failed, date: "Jan 20 2026, 9:24 PM", subtitleStyle: .secondary, operationIcon: .init(type: .transfer, status: .failed, isOutgoing: true), iconGlyph: nil, menuSections: []),
            onAction: { _ in }
        )
    }
    .background(DesignSystem.Color.bgSecondary)
}
