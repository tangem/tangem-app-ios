//
//  WalletConnectNetworksSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectNetworksSelectorView: View {
    @ObservedObject var viewModel: WalletConnectNetworksSelectorViewModel

    var body: some View {
        VStack(spacing: 14) {
            requiredNetworksAreUnavailableSection
            availableSection
            notAddedSection
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var requiredNetworksAreUnavailableSection: some View {
        if let viewState = viewModel.state.requiredNetworksAreUnavailableSection {
            VStack(spacing: .zero) {
                WalletConnectWarningNotificationView(viewModel: viewState.notificationViewModel)

                Divider()
                    .frame(height: 1)
                    .overlay(Colors.Stroke.primary)

                ForEach(viewState.blockchains) { blockchainViewState in
                    missingRequiredBlockchainRow(blockchainViewState, requiredLabel: viewState.requiredLabel)
                        .padding(.horizontal, 14)
                }
            }
            .background(Colors.Background.action)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var availableSection: some View {
        if !viewModel.state.availableSection.blockchains.isEmpty {
            sectionContainer(viewModel.state.availableSection.headerTitle) {
                ForEach(indexed: viewModel.state.availableSection.blockchains.indexed(), content: availableBlockchainRow)
            }
        }
    }

    @ViewBuilder
    private var notAddedSection: some View {
        if !viewModel.state.notAddedSection.blockchains.isEmpty {
            sectionContainer(viewModel.state.notAddedSection.headerTitle) {
                ForEach(viewModel.state.notAddedSection.blockchains, content: notAddedBlockchainRow)
            }
        }
    }

    private func sectionContainer<Content: View>(_ headerTitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(headerTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.top, 12)
                .padding(.bottom, 8)

            content()
        }
        .padding(.horizontal, 14)
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func missingRequiredBlockchainRow(
        _ blockchainViewState: WalletConnectNetworksSelectorViewState.BlockchainViewState,
        requiredLabel: String
    ) -> some View {
        blockchainRow(blockchainViewState, blockchainIconBackgroundColor: Colors.Button.secondary, blockchainNameColor: Colors.Text.tertiary) {
            Text(requiredLabel)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
    }

    private func availableBlockchainRow(
        blockchainIndex: Int,
        viewState: WalletConnectNetworksSelectorViewState.AvailableSection.AvailableBlockchain
    ) -> some View {
        blockchainRow(viewState.blockchainViewState, blockchainIconBackgroundColor: .clear, blockchainNameColor: Colors.Text.primary1) {
            if viewModel.state.requiredNetworksAreUnavailableSection == nil {
                Toggle("", isOn: bindingFor(availableBlockchain: viewState, index: blockchainIndex))
                    .tint(Colors.Control.checked)
                    .disabled(viewState.isReadOnly)
            }
        }
    }

    private func notAddedBlockchainRow(viewState: WalletConnectNetworksSelectorViewState.BlockchainViewState) -> some View {
        blockchainRow(viewState, blockchainIconBackgroundColor: Colors.Button.secondary, blockchainNameColor: Colors.Text.tertiary) {
            EmptyView()
        }
    }

    private func blockchainRow<TrailingContent: View>(
        _ state: WalletConnectNetworksSelectorViewState.BlockchainViewState,
        blockchainIconBackgroundColor: Color,
        blockchainNameColor: Color,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) -> some View {
        HStack(spacing: .zero) {
            state.iconAsset.image
                .resizable()
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(blockchainIconBackgroundColor)
                }

            Spacer()
                .frame(width: 12)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(state.name)
                    .style(Fonts.Bold.subheadline, color: blockchainNameColor)

                Text(state.currencySymbol)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: .zero)

            trailingContent()
        }
        .lineLimit(1)
        .padding(.vertical, 14)
    }

    private func bindingFor(
        availableBlockchain: WalletConnectNetworksSelectorViewState.AvailableSection.AvailableBlockchain,
        index: Int
    ) -> Binding<Bool> {
        switch availableBlockchain {
        case .required:
            return .constant(true)

        case .optional(let optionalBlockchain):
            return Binding(
                get: { optionalBlockchain.isSelected },
                set: { isSelected in
                    viewModel.handle(
                        viewEvent: .optionalBlockchainSelectionChanged(index: index, isSelected: isSelected)
                    )
                }
            )
        }
    }
}
