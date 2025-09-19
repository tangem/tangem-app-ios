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

struct BottomSheetHeaderView<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: () -> Leading
    private let trailing: () -> Trailing

    private var subtitleSpacing: CGFloat = 12
    private var verticalPadding: CGFloat = 12

    init(
        title: String,
        subtitle: String? = nil,
        leading: @escaping (() -> Leading) = { EmptyView() },
        trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Title layer
            VStack(spacing: subtitleSpacing) {
                Text(title)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                if let subtitle {
                    Text(subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }

            // Buttons layer
            HStack(spacing: .zero) {
                leading()

                Spacer()

                trailing()
            }
        }
        .infinityFrame(axis: .horizontal)
        .multilineTextAlignment(.center)
        .padding(.vertical, verticalPadding)
    }
}

// MARK: - Setupable

extension BottomSheetHeaderView: Setupable {
    func subtitleSpacing(_ spacing: CGFloat) -> Self {
        map { $0.subtitleSpacing = spacing }
    }

    func verticalPadding(_ padding: CGFloat) -> Self {
        map { $0.verticalPadding = padding }
    }
}
