//
//  ManageTokensView.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
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
            LazyVStack {
                if #available(iOS 15.0, *) {} else {
                    SearchBar(text: $viewModel.enteredSearchText.value, placeholder: Localization.commonSearch)
                        .padding(.horizontal, 8)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                divider

                ForEach(viewModel.tokenViewModels) {
                    ManageTokensItemView(viewModel: $0)
                        .padding(.horizontal)

                    divider
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                Color.clear.frame(width: 10, height: 58, alignment: .center)
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding([.leading])
    }

    @ViewBuilder private var titleView: some View {
        Text(Localization.addTokensTitle)
            .font(Font.system(size: 30, weight: .bold, design: .default))
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder private var overlay: some View {
        // TODO: - Demo
        VStack {
            Spacer()

            // TODO: - Need fot logic scan wallet on task: https://tangem.atlassian.net/browse/IOS-4651
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
