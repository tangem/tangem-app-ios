//
//  TokenDetailsActionsBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct TokenDetailsActionsBottomSheetView: View {
    let viewModel: TokenDetailsActionsBottomSheetViewModel

    @ScaledMetric(wrappedValue: .unit(.x4)) private var horizontalPadding: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x4)) private var bottomPadding: CGFloat

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                title: viewModel.title,
                backgroundColor: Color.Tangem.Surface.level2,
                closeButtonAction: viewModel.onClose
            )

            TokenDetailsActionRowsListView(items: viewModel.items)
                .padding(.horizontal, horizontalPadding)

            closeButton
                .padding(.horizontal, horizontalPadding)
                .padding(.top, bottomPadding)
                .padding(.bottom, bottomPadding)
        }
        .background(Color.Tangem.Surface.level2)
    }

    private var closeButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonClose)),
            action: viewModel.onClose
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
    }
}
