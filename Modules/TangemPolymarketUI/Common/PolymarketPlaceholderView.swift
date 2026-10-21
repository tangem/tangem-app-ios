//
//  PolymarketPlaceholderView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketPlaceholderView: View {
    private let icon: ImageType
    private let message: String
    private let action: Action?

    public init(icon: ImageType, message: String, action: Action? = nil) {
        self.icon = icon
        self.message = message
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Constants.spacing) {
            VStack(spacing: Constants.messageSpacing) {
                iconView

                Text(message)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
            }

            if let action {
                TangemUI.Button(label: action.title, accessibilityLabel: action.title, action: action.handler)
                    .size(.x9)
                    .styleType(.secondary(.default))
                    .iconEnd(action.icon)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(maxWidth: .infinity)
    }

    private var iconView: some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.iconSide, height: Constants.iconSide)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: Constants.iconContainerSide, height: Constants.iconContainerSide)
            .background(DesignSystem.Color.bgTransparentSecondary, in: Circle())
            .opacity(Constants.iconContainerOpacity)
            .accessibilityHidden(true)
    }
}

// MARK: - Action

public extension PolymarketPlaceholderView {
    struct Action {
        let title: String
        let icon: ImageType?
        let handler: () -> Void

        public init(title: String, icon: ImageType?, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.handler = handler
        }
    }
}

// MARK: - Constants

private extension PolymarketPlaceholderView {
    enum Constants {
        static let spacing: CGFloat = 24
        static let messageSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 48
        static let iconSide: CGFloat = 20
        static let iconContainerSide: CGFloat = 40
        static let iconContainerOpacity: Double = 0.9
    }
}

// MARK: - Previews

#Preview {
    PolymarketPlaceholderView(
        icon: DesignSystem.Icons.Info.regular20,
        message: "You don't have any operations yet",
        action: .init(title: "Explore events", icon: DesignSystem.Icons.Globe.regular20, handler: {})
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
