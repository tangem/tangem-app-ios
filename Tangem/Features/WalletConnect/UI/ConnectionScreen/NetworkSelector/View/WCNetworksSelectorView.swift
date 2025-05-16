//
//  WCNetworksSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import BlockchainSdk

struct WCNetworksSelectorView: View {
    @StateObject private var viewModel: WCNetworksSelectorViewModel
    
    init(input: WCNetworkSelectorInput) {
        _viewModel = .init(wrappedValue: .init(input: input))
    }

    var body: some View {
        content
    }

    private var content: some View {
        VStack(spacing: 12) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    requiredBlockchainsSection

                    blockchainsSection(title: "Available networks",state: [.selected, .notSelected, .required])

                    blockchainsSection(title: "Not added", state: [.notAdded])
                }
                .padding(.init(top: 0, leading: 16, bottom: Constants.scrollContentBottomPadding, trailing: 16))
            }
        }
        .overlay(alignment: .bottom, content: doneButton)
    }

    @ViewBuilder
    private func doneButton() -> some View {
        MainButton(
            title: "Done",
            isDisabled: viewModel.isDoneButtonDisabled,
            action: { viewModel.handleViewAction(.selectNetworks) }
        )
        .padding(.init(top: 0, leading: 16, bottom: 14, trailing: 16))
        .background(
            ListFooterOverlayShadowView()
                .padding(.top, -50)
        )
    }
}

// MARK: - Header

private extension WCNetworksSelectorView {
    var header: some View {
        WalletConnectNavigationBarView(
            title: "Choose network",
            backButtonAction: { viewModel.handleViewAction(.returnToConnectionDetails) }
        )
    }
}

// MARK: - Sections

private extension WCNetworksSelectorView {
    @ViewBuilder
    var requiredBlockchainsSection: some View {
        let blockchains = viewModel.filterBlockchain(by: [.requiredToAdd])

        if blockchains.isNotEmpty {
            VStack(alignment: .leading, spacing: 8) {
                WCRequiredNetworksView(blockchainNames: viewModel.requiredBlockchainNames)
                    .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 16))

                Separator(height: .minimal, color: Colors.Stroke.primary)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(blockchains) {
                        blockchainRow($0)
                            .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 16))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .foregroundStyle(Colors.Background.action)
            )
        }
    }

    @ViewBuilder
    func blockchainsSection(
        title: String,
        state: [WCSelectBlockchainItemState]
    ) -> some View {
        let blockchains = viewModel.filterBlockchain(by: state)

        if blockchains.isNotEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(blockchains) {
                        blockchainRow($0)
                            .padding(.vertical, 14)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .foregroundStyle(Colors.Background.action)
            )
        }
    }
}

// MARK: - Blockchain row

private extension WCNetworksSelectorView {
    func blockchainRow(_ blockchain: WCSelectedBlockchainItem) -> some View {
        HStack(spacing: 0) {
            tokenIconInfo(blockchain)

            Text(blockchain.name)
                .style(
                    Fonts.Bold.subheadline,
                    color: blockchain.state != .requiredToAdd ? Colors.Text.primary1 : Colors.Text.tertiary
                )
                .padding(.trailing, 4)

            Text(blockchain.state == .requiredToAdd ? blockchain.tokenTypeName : blockchain.currencySymbol)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer()

            rightContent(for: blockchain)
        }
    }

    @ViewBuilder
    func tokenIconInfo(_ blockchain: WCSelectedBlockchainItem) -> some View {
        if let tokenIconInfo = blockchain.tokenIconInfo {
            TokenIcon(tokenIconInfo: tokenIconInfo, size: .init(bothDimensions: 24))
                .padding(.trailing, 12)
                .saturation(viewModel.checkBlockchainItemDisabled(blockchain) ? 0 : 1)
        }
    }

    @ViewBuilder
    func rightContent(for blockchain: WCSelectedBlockchainItem) -> some View {
        switch blockchain.state {
        case .notAdded:
            EmptyView()
        case .selected, .notSelected:
            if viewModel.isAllRequiredChainsAdded {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { viewModel.selectedBlockchains.contains(blockchain) },
                        set: { isSelected in
                            viewModel.handleViewAction(.blockchainSelectionChanged(blockchain, isSelected))
                        }
                    )
                )
                .toggleStyle(.switch)
                .tint(Colors.Control.checked)
            }
        case .required:
            Toggle("", isOn: .constant(true))
                .toggleStyle(.switch)
                .tint(Colors.Control.checked)
                .disabled(true)
        case .requiredToAdd:
            Text("Required")
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static var scrollContentBottomPadding: CGFloat { MainButton.Size.default.height + 34 } // summ padding between scroll content and overlay buttons
}
