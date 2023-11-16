//
//  ManageTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensNetworkSelectorView: View {
    @ObservedObject var viewModel: ManageTokensNetworkSelectorViewModel

    var body: some View {
        GroupedScrollView {
            if let notificationViewModel = viewModel.notificationViewModel {
                ManageTokensNetworkSelectorNotificationView(viewModel: notificationViewModel)

                Spacer(minLength: 14)
            }

            if !viewModel.currentWalletName.isEmpty {
                walletSelectorContent

                Spacer(minLength: 14)
            }

            if !viewModel.nativeSelectorItems.isEmpty {
                Spacer(minLength: 10)

                nativeNetworksContent
            }

            if !viewModel.nonNativeSelectorItems.isEmpty {
                Spacer(minLength: 24)

                noneNativeNetworksContent
            }
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
    }

    private var walletSelectorContent: some View {
        HStack(spacing: 16) {
            Text(Localization.manageTokensNetworkSelectorWallet)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Spacer(minLength: 0)

            Text(viewModel.currentWalletName)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

            Assets.chevron.image
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .contentShape(Rectangle())
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(Constants.cornerRadius)
        .onTapGesture {
            viewModel.selectWalletActionDidTap()
        }
    }

    private var nativeNetworksContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.manageTokensNetworkSelectorNativeTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Text(Localization.manageTokensNetworkSelectorNativeSubtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: 10)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.nativeSelectorItems) {
                    ManageTokensNetworkSelectorItemView(viewModel: $0)
                }
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private var noneNativeNetworksContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: viewModel.displayNonNativeNetworkAlert) {
                HStack(spacing: 4) {
                    Text(Localization.manageTokensNetworkSelectorNonNativeTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Assets.infoIconMini.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(size: .init(bothDimensions: 20))
                        .foregroundColor(Colors.Icon.inactive)

                    Spacer()
                }
            }

            Spacer(minLength: 10)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.nonNativeSelectorItems) {
                    ManageTokensNetworkSelectorItemView(viewModel: $0)
                }
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }
}

private extension ManageTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
