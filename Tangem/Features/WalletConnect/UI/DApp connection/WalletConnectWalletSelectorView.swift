//
//  WalletConnectWalletSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectWalletSelectorView: View {
    @ObservedObject private var viewModel: WalletConnectWalletSelectorViewModel

    private let scrollProxy: ScrollViewProxy
    private let initialSelectedScrollID: String?
    @Namespace private var selectionNamespace

    init(viewModel: WalletConnectWalletSelectorViewModel, scrollProxy: ScrollViewProxy) {
        self.viewModel = viewModel
        self.scrollProxy = scrollProxy

        // [REDACTED_USERNAME]: ScrollViewProxy.scrollTo(_:anchor:) does not allow to specify a content offset
        // scrolling to the next (if any) wallet after the selected one looks visually better

        if let selectedWalletIndex = viewModel.state.wallets.firstIndex(where: { $0.isSelected }) {
            let isNotLast = selectedWalletIndex < viewModel.state.wallets.count - 1
            let anchorWallet = isNotLast
                ? viewModel.state.wallets[selectedWalletIndex + 1]
                : viewModel.state.wallets[selectedWalletIndex]

            initialSelectedScrollID = anchorWallet.id.stringValue
        } else {
            initialSelectedScrollID = nil
        }
    }

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(indexed: viewModel.state.wallets.indexed()) { index, walletViewModel in
                ZStack(alignment: .bottom) {
                    walletRowView(walletViewModel)
                    walletsDivider(index)
                    walletSelectionBorder(walletViewModel)
                }
                .animation(
                    .easeInOut(duration: WalletConnectWalletSelectorViewModel.selectionAnimationDuration),
                    value: walletViewModel.isSelected
                )
                .id(walletViewModel.id)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .onAppear {
            scrollProxy.scrollTo(initialSelectedScrollID, anchor: .bottom)
        }
    }

    private func walletRowView(_ walletViewModel: WalletConnectWalletSelectorViewState.UserWallet) -> some View {
        Button(action: { viewModel.handle(viewEvent: .selectedUserWalletUpdated(walletViewModel.domainModel)) }) {
            HStack(spacing: 12) {
                walletImage(walletViewModel)
                    .frame(width: 36, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(walletViewModel.name)
                        .style(Fonts.Bold.subheadline, color: walletViewModel.isSelected ? Colors.Text.primary1 : Colors.Text.secondary)

                    walletDescription(walletViewModel.description)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
            .padding(14)
            .contentShape(.rect)
        }
        .disabled(walletViewModel.isLocked)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func walletsDivider(_ index: Int) -> some View {
        if index < viewModel.state.wallets.count - 1 {
            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)
                .padding(.leading, 62)
                .padding(.trailing, 14)
        }
    }

    @ViewBuilder
    private func walletSelectionBorder(_ walletViewModel: WalletConnectWalletSelectorViewState.UserWallet) -> some View {
        if walletViewModel.isSelected {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Text.accent, lineWidth: 1)

                RoundedRectangle(cornerRadius: 14)
                    .stroke(Colors.Text.accent.opacity(0.2), lineWidth: 2)
                    .padding(-1)
            }
            .matchedGeometryEffect(id: "selection", in: selectionNamespace)
        }
    }

    @ViewBuilder
    private func walletImage(_ walletViewModel: WalletConnectWalletSelectorViewState.UserWallet) -> some View {
        switch walletViewModel.imageState {
        case .loading:
            SkeletonView()

        case .content(let image):
            image.resizable()
        }
    }

    private func walletDescription(_ descriptionViewModel: WalletConnectWalletSelectorViewState.UserWallet.Description) -> some View {
        HStack(spacing: 2) {
            Text(descriptionViewModel.tokensCount)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            if descriptionViewModel.balanceState != .empty {
                Text(descriptionViewModel.delimiter)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                LoadableBalanceView(
                    state: descriptionViewModel.balanceState,
                    style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                    loader: .init(size: CGSize(width: 40, height: 12))
                )
            }
        }
    }
}
