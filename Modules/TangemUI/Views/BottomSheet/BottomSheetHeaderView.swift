//
//  BottomSheetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct BottomSheetHeaderView<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: Leading
    private let trailing: Trailing
    private let titleAccessibilityIdentifier: String?

    private var subtitleSpacing: CGFloat = 12
    private var verticalPadding: CGFloat = 12

    public init(
        title: String,
        subtitle: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder leading: @escaping (() -> Leading) = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        ZStack(alignment: .center) {
            // Title layer
            VStack(spacing: subtitleSpacing) {
                Text(title)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .accessibilityIdentifier(titleAccessibilityIdentifier)

                if let subtitle {
                    Text(subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }

            // Buttons layer
            HStack(spacing: .zero) {
                leading

                Spacer()

                trailing
            }
        }
        .infinityFrame(axis: .horizontal)
        .multilineTextAlignment(.center)
        .padding(.vertical, verticalPadding)
    }
}

// MARK: - Setupable

extension BottomSheetHeaderView: Setupable {
    public func subtitleSpacing(_ spacing: CGFloat) -> Self {
        map { $0.subtitleSpacing = spacing }
    }

    public func verticalPadding(_ padding: CGFloat) -> Self {
        map { $0.verticalPadding = padding }
    }
}
