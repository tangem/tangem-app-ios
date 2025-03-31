//
//  ActionButtonsBuyView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct ActionButtonsBuyView: View {
    @ObservedObject var viewModel: ActionButtonsBuyViewModel

    var body: some View {
        content
            .navigationTitle(Localization.actionButtonsBuyNavigationBarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: { viewModel.handleViewAction(.close) })
                }
            }
            .transition(.opacity.animation(.easeInOut))
            .onAppear {
                viewModel.handleViewAction(.onAppear)
            }
            .bindAlert($viewModel.alert)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
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
                .padding(.horizontal, 16)

                HotCryptoView(
                    items: viewModel.hotCryptoItems,
                    action: {
                        viewModel.handleViewAction(.didTapHotCrypto($0))
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .background(Colors.Background.tertiary.ignoresSafeArea(.all))
        .scrollDismissesKeyboardCompat(.immediately)
    }
}
