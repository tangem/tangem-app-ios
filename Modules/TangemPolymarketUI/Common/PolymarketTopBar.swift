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

public struct PolymarketTopBar<Trailing: View>: View {
    private let title: String?
    private let onBack: (() -> Void)?
    private let onClose: (() -> Void)?
    private let trailing: Trailing

    public init(
        title: String? = nil,
        onBack: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.onBack = onBack
        self.onClose = onClose
        self.trailing = trailing()
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
                    NavigationBarButton.back(action: onBack)
                        .accessibilityLabel(Localization.commonBack)
                }

                Spacer(minLength: 0)

                if let onClose {
                    NavigationBarButton.close(action: onClose)
                        .accessibilityLabel(Localization.commonClose)
                }

                trailing
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: Constants.height)
    }
}

// MARK: - Trailing-less shorthand

public extension PolymarketTopBar where Trailing == EmptyView {
    init(title: String? = nil, onBack: (() -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack, onClose: onClose, trailing: { EmptyView() })
    }
}

// MARK: - Constants

private enum Constants {
    static let horizontalPadding: CGFloat = 16
    static let height: CGFloat = 44
    static let titleInset: CGFloat = 56
}
