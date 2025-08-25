//
//  WalletConnectDAppConnectionRequestView+NetworksSection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension WalletConnectDAppConnectionRequestView {
    struct NetworksSection: View {
        let viewModel: WalletConnectDAppConnectionRequestViewState.NetworksSection
        let tapAction: () -> Void

        var body: some View {
            Button(action: tapAction) {
                HStack(spacing: .zero) {
                    viewModel.iconAsset.image
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Colors.Icon.accent)

                    Spacer()
                        .frame(width: 8)

                    Text(viewModel.label)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    Spacer(minLength: .zero)

                    trailingView

                    viewModel.trailingIconAsset?.image
                        .resizable()
                        .frame(width: 18, height: 24)
                        .foregroundStyle(Colors.Icon.informative)
                }
                .padding(.vertical, 12)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private var trailingView: some View {
            switch viewModel.state {
            case .loading:
                SkeletonView()
                    .frame(width: 88, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

            case .content(let contentState):
                switch contentState.selectionMode {
                case .available(let availableSelectionMode):
                    availableSelectionTrailingView(availableSelectionMode)
                case .requiredNetworksAreMissing:
                    EmptyView()
                }
            }
        }

        private func availableSelectionTrailingView(
            _ availableSelectionMode: WalletConnectDAppConnectionRequestViewState.NetworksSection.AvailableSelectionMode
        ) -> some View {
            HStack(spacing: -8) {
                ForEach(availableSelectionMode.blockchainLogoAssets.indexed(), id: \.0) { index, blockchainLogoAsset in
                    ZStack {
                        Circle()
                            .fill(Colors.Background.action)
                            .frame(width: 24, height: 24)

                        blockchainLogoAsset.image
                            .resizable()
                            .clipShape(.circle)
                            .frame(width: 20, height: 20)
                    }
                }

                if let remainingBlockchainsCounter = availableSelectionMode.remainingBlockchainsCounter {
                    ZStack {
                        Circle()
                            .fill(Colors.Background.action)
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(Colors.Icon.primary1.opacity(0.1))
                            .frame(width: 24, height: 24)

                        Circle()
                            .strokeBorder(Colors.Background.action, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Text(remainingBlockchainsCounter)
                            .style(Fonts.Bold.caption2, color: Colors.Text.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
