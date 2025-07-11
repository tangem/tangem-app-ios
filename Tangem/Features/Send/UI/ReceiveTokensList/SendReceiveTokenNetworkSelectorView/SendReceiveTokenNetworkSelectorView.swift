//
//  SendReceiveTokenNetworkSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendReceiveTokenNetworkSelectorView: View {
    @ObservedObject var viewModel: SendReceiveTokenNetworkSelectorViewModel

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: .zero) {
                BottomSheetHeaderView(title: viewModel.state.isSuccess ? Localization.commonChooseNetwork : "", trailing: {
                    RoundedButton(style: .icon(Assets.cross, color: Colors.Icon.secondary), action: viewModel.dismiss)
                })
                .padding(.vertical, 4)
                .padding(.horizontal, 16)

                scrollContent
            }

            overlayContent
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.action
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if case .success(let items) = viewModel.state {
            ScrollView(.vertical) {
                GroupedSection(items) {
                    SendReceiveTokenNetworkSelectorNetworkView(viewModel: $0)
                }
                .backgroundColor(Colors.Background.action)
                .interItemSpacing(16)
                .innerContentPadding(16)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollBounceBehaviorBackport(.basedOnSize)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .padding(.vertical, 150)
        case .success:
            EmptyView()
        case .failure(let error):
            BottomSheetErrorContentView(
                title: Localization.expressSwapNotSupportedText,
                subtitle: error.localizedDescription,
                gotItButtonAction: viewModel.dismiss
            )
            .padding(.bottom, 16)
        }
    }
}
