//
//  SendReceiveTokensListView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendReceiveTokensListView: View {
    @ObservedObject var viewModel: SendReceiveTokensListViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            BottomSheetHeaderView(title: Localization.commonChooseToken, trailing: {
                CircleButton.close(action: viewModel.dismiss)
            })
            .padding(.vertical, 4)
            .padding(.horizontal, 16)

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: Localization.commonSearch,
                style: .focused
            )
            .innerPadding(8)
            .onEditingChanged(viewModel.focusChangedInSearchBar)
            .focused($isFocused)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            GroupedScrollView {
                if let notification = viewModel.onboardNotification {
                    NotificationView(input: notification)
                        .padding(.bottom, 14)
                        .transition(.notificationTransition.animation(.linear(duration: 0.2)))
                }

                GroupedSection(viewModel.items) {
                    SendReceiveTokensListTokenView(viewModel: $0)
                }
                .backgroundColor(Colors.Background.action)
                .horizontalPadding(16)
                .interItemSpacing(16)
                .innerContentPadding(16)

                if viewModel.canFetchMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
                        .padding(.vertical, 16)
                        .onAppear(perform: viewModel.fetchMore)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.default, value: viewModel.onboardNotification == nil)
        .background(Colors.Background.tertiary)
        .onReceive(viewModel.$isFocused) { isFocused in
            self.isFocused = isFocused
        }
    }
}
