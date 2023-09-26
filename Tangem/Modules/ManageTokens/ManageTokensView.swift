//
//  ManageTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk
import AlertToast

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    var body: some View {
        ZStack {
            list

            overlay
        }
        .scrollDismissesKeyboardCompat(true)
        .navigationBarTitle(Text(Localization.addTokensTitle), displayMode: .automatic)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .toast(isPresenting: $viewModel.showToast) {
            AlertToast(type: .complete(Colors.Icon.accent), title: Localization.contractAddressCopiedMessage)
        }
        .searchableCompat(text: $viewModel.enteredSearchText.value)
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if #available(iOS 15.0, *) {} else {
                    SearchBar(text: $viewModel.enteredSearchText.value, placeholder: Localization.commonSearch)
                        .padding(.horizontal, 8)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                ForEach(viewModel.tokenViewModels) {
                    ManageTokensItemView(viewModel: $0)
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                Color.clear.frame(height: 58)
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding([.leading])
    }

    @ViewBuilder private var titleView: some View {
        Text(Localization.addTokensTitle)
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
    }

    @ViewBuilder private var overlay: some View {
        // [REDACTED_TODO_COMMENT]
        VStack {
            Spacer()

            // [REDACTED_TODO_COMMENT]
            GenerateAddressesView(
                numberOfNetworks: 3,
                currentWalletNumber: 1,
                totalWalletNumber: 2,
                didTapGenerate: {}
            )
            .padding(.zero)
        }
    }
}
