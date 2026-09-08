//
//  PolymarketTopBar.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketTopBar: View {
    private let title: String?
    private let onBack: (() -> Void)?
    private let onClose: (() -> Void)?

    public init(title: String? = nil, onBack: (() -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.title = title
        self.onBack = onBack
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            if let title {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, Constants.titleInset)
            }

            HStack(spacing: 0) {
                if let onBack {
                    button(icon: DesignSystem.Icons.ChevronLeft.regular20, label: Localization.commonBack, action: onBack)
                }

                Spacer(minLength: 0)

                if let onClose {
                    button(icon: DesignSystem.Icons.Cross.regular20, label: Localization.commonClose, action: onClose)
                }
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: Constants.height)
    }

    private func button(icon: ImageType, label: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            icon.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(size: .init(bothDimensions: Constants.buttonSide))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
        .accessibilityLabel(label)
    }
}

// MARK: - Constants

private extension PolymarketTopBar {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let height: CGFloat = 44
        static let buttonSide: CGFloat = 44
        static let titleInset: CGFloat = 56
    }
}
