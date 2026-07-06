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
import TangemAccessibilityIdentifiers

struct SendReceiveTokenNetworkSelectorView: View {
    @ObservedObject var viewModel: SendReceiveTokenNetworkSelectorViewModel

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: .zero) {
                BottomSheetHeaderView(
                    title: viewModel.headerTitle,
                    trailing: {
                        NavigationBarButton.close(action: viewModel.dismiss)
                    }
                )
                .padding(.vertical, 4)
                .padding(.horizontal, 16)

                scrollContent
            }

            overlayContent
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.state)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.primary
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if case .networks(let items) = viewModel.state {
            ScrollView(.vertical) {
                VStack(spacing: .zero) {
                    if let notification = viewModel.notification {
                        NotificationView(input: notification)
                            .padding(.horizontal, 16)
                    }

                    GroupedSection(items) {
                        SendReceiveTokenNetworkSelectorNetworkView(viewModel: $0)
                    }
                    .backgroundColor(Colors.Background.primary)
                    .interItemSpacing(16)
                    .innerContentPadding(16)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .padding(.vertical, 150)
        case .networks:
            EmptyView()
        case .swapRequired(let viewData):
            SendReceiveTokenSwapRequiredContentView(viewData: viewData)
                .accessibilityElement(children: .contain)
        case .notSupported(let text):
            BottomSheetErrorContentView(
                title: viewModel.notSupportedTitle,
                subtitle: text,
                secondaryButton: .init(
                    title: Localization.commonGotIt,
                    style: .secondary,
                    accessibilityIdentifier: SendAccessibilityIdentifiers.networkSelectorGotItButton,
                    action: viewModel.dismiss
                )
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SendAccessibilityIdentifiers.networkSelectorErrorTitle)
        }
    }
}
