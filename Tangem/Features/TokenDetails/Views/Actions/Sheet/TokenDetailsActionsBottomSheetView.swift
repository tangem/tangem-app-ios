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
    @ObservedObject var viewModel: TokenDetailsActionsBottomSheetViewModel

    @ScaledMetric(wrappedValue: .unit(.x4)) private var horizontalPadding: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x4)) private var bottomPadding: CGFloat

    var body: some View {
        Group {
            switch viewModel.state {
            case .receive(let receiveViewModel):
                ReceiveMainView(viewModel: receiveViewModel)
                    .transition(.content)

            case .actions(let items):
                actionsContent(items: items)
                    .transition(.content)
            }
        }
        .animation(.contentFrameUpdate, value: viewModel.state.id)
    }

    private func actionsContent(items: [TokenDetailsActionRowItem]) -> some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                title: viewModel.title,
                backgroundColor: Color.Tangem.Surface.level2,
                closeButtonAction: viewModel.onClose
            )

            TokenDetailsActionRowsListView(items: items)
                .padding(.horizontal, horizontalPadding)

            closeButton
                .padding(.horizontal, horizontalPadding)
                .padding(.top, bottomPadding)
                .padding(.bottom, bottomPadding)
        }
        .background(Color.Tangem.Surface.level2)
        // Scoped to the actions branch so receive keeps ReceiveMainView's own configuration; the
        // frame-update animation must live here to keep the actions->receive height change animated.
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Color.Tangem.Surface.level2
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var closeButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonClose)),
            action: viewModel.onClose
        )
        .setStyleType(.secondary)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
}
