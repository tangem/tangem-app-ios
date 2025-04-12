//
//  ActionButtonsSellView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct ActionButtonsSellView: View {
    @ObservedObject var viewModel: ActionButtonsSellViewModel

    var body: some View {
        content
            .navigationTitle(Localization.actionButtonsSellNavigationBarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: { viewModel.handleViewAction(.close) })
                }
            }
            .onAppear {
                viewModel.handleViewAction(.onAppear)
            }
            .bindAlert($viewModel.alert)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                notifications

                TokenSelectorView(
                    viewModel: viewModel.tokenSelectorViewModel,
                    tokenCellContent: { token in
                        ActionButtonsTokenSelectItemView(model: token) {
                            viewModel.handleViewAction(.didTapToken(token))
                        }
                        .padding(.vertical, 16)
                    },
                    emptySearchContent: {
                        Text(viewModel.tokenSelectorViewModel.strings.emptySearchMessage)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            .multilineTextAlignment(.center)
                            .animation(.default, value: viewModel.tokenSelectorViewModel.searchText)
                    }
                )
            }
            .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.ignoresSafeArea(.all))
        .scrollDismissesKeyboardCompat(.immediately)
    }

    private var notifications: some View {
        ForEach(viewModel.notificationInputs) {
            NotificationView(input: $0)
        }
    }
}
