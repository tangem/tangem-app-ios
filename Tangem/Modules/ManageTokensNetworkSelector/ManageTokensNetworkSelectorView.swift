//
//  ManageTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import AlertToast

struct ManageTokensNetworkSelectorView: View {
    @ObservedObject var viewModel: ManageTokensNetworkSelectorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 10)

                walletSelectorContent

                if !viewModel.nativeSelectorItems.isEmpty {
                    Spacer(minLength: 24)

                    nativeNetworksContent
                }

                if !viewModel.nonNativeSelectorItems.isEmpty {
                    Spacer(minLength: 24)

                    noneNativeNetworksContent
                }
            }
            .padding(.horizontal, 16)
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    private var walletSelectorContent: some View {
        Group {
            HStack(spacing: 16) {
                Text("Wallet")
                    .lineLimit(1)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                Spacer(minLength: 0)

                Text(viewModel.currentWalletName)
                    .lineLimit(1)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

                Assets.chevron.image
                    .frame(width: 24, height: 24)
                    .foregroundColor(Colors.Icon.informative)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 19)
            .contentShape(Rectangle())
            .background(Colors.Background.primary)
            .onTapGesture {
                viewModel.selectWalletActionDidTap()
            }
        }
        .cornerRadiusContinuous(Constants.cornerRadius)
    }

    private var nativeNetworksContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localization.manageTokensNetworkSelectorNativeTitle)
                .lineLimit(1)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Text(Localization.manageTokensNetworkSelectorNativeSubtitle)
                .lineLimit(2)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: 8)

            Group {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.nativeSelectorItems) {
                        ManageTokensNetworkSelectorItemView(viewModel: $0)
                    }
                }
                .background(Colors.Background.primary)
            }
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private var noneNativeNetworksContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localization.manageTokensNetworkSelectorNonNativeTitle)
                .lineLimit(1)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Text(Localization.manageTokensNetworkSelectorNonNativeSubtitle)
                .lineLimit(2)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: 8)

            Group {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.nonNativeSelectorItems) {
                        ManageTokensNetworkSelectorItemView(viewModel: $0)
                    }
                }
                .background(Colors.Background.primary)
            }
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }
}

private extension ManageTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
