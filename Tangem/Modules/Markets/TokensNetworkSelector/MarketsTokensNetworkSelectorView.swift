//
//  MarketsTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by skibinalexander on 21.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokensNetworkSelectorView: View {
    @ObservedObject var viewModel: MarketsTokensNetworkSelectorViewModel
    @Binding var walletSelectorViewModel: WalletSelectorViewModel?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 14) {
                if let walletSelectorViewModel = viewModel.walletSelectorViewModel {
                    MarketsWalletSelectorView(viewModel: walletSelectorViewModel)
                        .onTapGesture {
                            viewModel.selectWalletActionDidTap()
                        }
                }

                contentView

                if !viewModel.pendingAdd.isEmpty {
                    MarketsGeneratedAddressView()
                }
            }
            .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
            .padding(.horizontal, 16)
            .padding(.bottom, 72)
            .navigationLinks(links)
            .adaptivePresentationDetents(isNavigationRequired: true)

            overlayButtonView
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .background(Colors.Background.action, ignoresSafeAreaEdges: .vertical)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.headerTokenInfoSpace) {
                Text(Localization.marketsSelectNetwork)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                tokenInfoView
            }

            networkListView
        }
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: Constants.cornerRadius)
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: 12) {
                IconView(url: viewModel.coinIconURL, size: .init(bothDimensions: 36), forceKingfisher: true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.coinName)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.coinSymbol)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                        Spacer()
                    }

                    Text(Localization.marketsAvailableNetworks)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var overlayButtonView: some View {
        VStack {
            Spacer()

            MainButton(
                title: Localization.commonContinue,
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isSaving,
                isDisabled: viewModel.isSaveDisabled,
                action: viewModel.saveChangesOnTapAction
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(LinearGradient(
                colors: [Colors.Background.primary, Colors.Background.primary, Colors.Background.primary.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .edgesIgnoringSafeArea(.bottom))
        }
    }

    private var networkListView: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.tokenItemViewModels) {
                MarketsTokensNetworkSelectorItemView(viewModel: $0, arrowWidth: 36)
            }
        }
    }
}

private extension MarketsTokensNetworkSelectorView {
    var links: some View {
        NavHolder()
            .navigation(item: $walletSelectorViewModel) {
                WalletSelectorView(viewModel: $0)
            }
    }
}

private extension MarketsTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
        static let headerTokenInfoSpace = 8.0
    }
}
