//
//  SendFeeSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendFeeSelectorView: View {
    // MARK: - View Model

    @ObservedObject
    var viewModel: SendFeeSelectorViewModel

    // MARK: - View Body

    var body: some View {
        content
            .floatingSheetConfiguration { configuration in
                configuration.sheetBackgroundColor = Colors.Background.tertiary
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = .consumeTouches
            }
    }

    // MARK: - Sub Views

    private var content: some View {
        FeeSelectorBottomSheetContainerView(
            state: viewModel.state.hashValue,
            button: button,
            headerContent: { header },
            descriptionContent: { description },
            mainContent: { FeeSelectorView(viewModel: viewModel.feeSelectorViewModel) }
        )
    }

    private var button: MainButton? {
        if case .summary = viewModel.state {
            return MainButton(settings: .init(title: Localization.commonConfirm, style: .primary, action: viewModel.userDidTapConfirmButton))
        }

        return nil
    }

    private var header: some View {
        BottomSheetHeaderView(
            title: viewModel.state.content.title,
            leading: { leadingHeaderButton },
            trailing: { trailingHeaderButton }
        )
    }

    @ViewBuilder
    private var description: some View {
        if let descripton = viewModel.state.description {
            Text(descripton)
                .environment(\.openURL, OpenURLAction { _ in
                    viewModel.openURL()
                    return .handled
                })
                .multilineTextAlignment(.center)
        }
    }

    private var leadingHeaderButton: some View {
        CircleButton.back(action: viewModel.userDidTapBackButton)
            .opacity(viewModel.state.content.headerButtonAction.isBack ? 1 : 0)
    }

    private var trailingHeaderButton: some View {
        CircleButton.close(action: viewModel.userDidTapDismissButton)
            .opacity(viewModel.state.content.headerButtonAction.isClose ? 1 : 0)
    }
}

// MARK: - Animation

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
}
