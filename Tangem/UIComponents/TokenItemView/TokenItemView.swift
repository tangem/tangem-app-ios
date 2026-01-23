//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers
import os

let _logger = Logger(subsystem: "com.app.example", category: "azaza")

struct TokenItemView: View {
    @ObservedObject private var viewModel: TokenItemViewModel

    private let roundedCornersConfiguration: RoundedCornersConfiguration?
    private let previewContentShapeCornerRadius: CGFloat

    var body: some View {
        TwoLineRowWithIcon(
            icon: { TokenItemViewLeadingComponent(from: viewModel) },
            primaryLeadingView: {
                HStack(spacing: 6) {
                    Text(viewModel.name)
                        .style(
                            Fonts.Bold.subheadline,
                            color: viewModel.hasError ? Colors.Text.tertiary : Colors.Text.primary1
                        )
                        .lineLimit(1)
                        .accessibilityIdentifier(MainAccessibilityIdentifiers.tokenTitle)

                    leadingBadge
                        .layoutPriority(1000.0)
                }
            },
            primaryTrailingView: {
                if viewModel.hasError, let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                } else {
                    HStack(spacing: 6) {
                        trailingBadge

                        LoadableTokenBalanceView(
                            state: viewModel.balanceFiat,
                            style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                            loader: .init(size: .init(width: 40, height: 12)),
                            accessibilityIdentifier: MainAccessibilityIdentifiers.tokenBalance(for: viewModel.name)
                        )
                        .layoutPriority(3)
                    }
                }
            },
            secondaryLeadingView: {
                if !viewModel.hasError {
                    HStack(spacing: 6) {
                        LoadableTextView(
                            state: viewModel.tokenPrice,
                            font: Fonts.Regular.caption1,
                            textColor: Colors.Text.tertiary,
                            loaderSize: .init(width: 52, height: 12)
                        )

                        TokenPriceChangeView(
                            state: viewModel.priceChangeState,
                            showSkeletonWhenLoading: false
                        )
                        .layoutPriority(1)
                    }
                    .layoutPriority(2)
                }
            },
            secondaryTrailingView: {
                if !viewModel.hasError {
                    LoadableTokenBalanceView(
                        state: viewModel.balanceCrypto,
                        style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                        loader: .init(size: .init(width: 40, height: 12))
                    )
                    .layoutPriority(3)
                }
            }
        )
        .padding(14)
        .background(background)
        .onTapGesture(perform: viewModel.tapAction)
        .highlightable(color: Colors.Button.primary.opacity(0.03))
        // `previewContentShape` must be called just before `contextMenu` call, otherwise visual glitches may occur
        .previewContentShape(cornerRadius: previewContentShapeCornerRadius)
        .contextMenu {
            ForEach(viewModel.contextActionSections, id: \.self) { section in
                Section {
                    ForEach(section.items, id: \.self) { menuAction in
                        contextMenuButton(for: menuAction)
                    }
                }
            }
        }
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
    }

    @ViewBuilder
    var leadingBadge: some View {
        switch viewModel.leadingBadge {
        case .pendingTransaction:
            ProgressDots(style: .small)
        case .rewards(let rewardsInfo):
            let _ = _logger.debug("got rewards for: \(viewModel.tokenItem, privacy: .public)")
            let _ = AppLogger.debug("got rewards for: \(viewModel.tokenItem)")
            TokenItemEarnBadgeView(
                rewardType: rewardsInfo.type,
                rewardValue: rewardsInfo.rewardValue,
                color: rewardsInfo.isActive ? Colors.Text.accent : Colors.Text.secondary,
                tapAction: viewModel.yieldApyTapAction,
                isUpdating: rewardsInfo.isUpdating
            )
        case .none:
            let _ = _logger.debug("got none for: \(viewModel.tokenItem, privacy: .public)")
            let _ = AppLogger.debug("got none for: \(viewModel.tokenItem)")
            EmptyView()
        }
    }

    @ViewBuilder
    var trailingBadge: some View {
        if case .isApproveNeeded = viewModel.trailingBadge {
            yieldWarningIcon
        } else {
            EmptyView()
        }
    }

    private var yieldWarningIcon: some View {
        Assets.attention20.image
            .resizable()
            .frame(width: 12, height: 12)
    }

    @ViewBuilder
    private var background: some View {
        if let roundedCornersConfiguration = roundedCornersConfiguration {
            Colors.Background.primary
                .cornerRadiusContinuous(
                    topLeadingRadius: roundedCornersConfiguration.topLeadingRadius,
                    bottomLeadingRadius: roundedCornersConfiguration.bottomLeadingRadius,
                    bottomTrailingRadius: roundedCornersConfiguration.bottomTrailingRadius,
                    topTrailingRadius: roundedCornersConfiguration.topTrailingRadius
                )
        } else {
            Colors.Background.primary
        }
    }

    @ViewBuilder
    private func contextMenuButton(for actionType: TokenActionType) -> some View {
        let action = { viewModel.didTapContextAction(actionType) }
        if actionType.isDestructive {
            Button(
                role: .destructive,
                action: action,
                label: {
                    labelForContextButton(with: actionType)
                }
            )
        } else {
            Button(action: action, label: {
                labelForContextButton(with: actionType)
            })
        }
    }

    private func labelForContextButton(with action: TokenActionType) -> some View {
        HStack {
            Text(action.title)
            action.icon.image
                .renderingMode(.template)
        }
    }
}

// MARK: - Initialization

extension TokenItemView {
    init(
        viewModel: TokenItemViewModel,
        cornerRadius: CGFloat,
        roundedCornersVerticalEdge: RoundedCornersVerticalEdge?
    ) {
        self.viewModel = viewModel
        previewContentShapeCornerRadius = cornerRadius

        switch roundedCornersVerticalEdge {
        case .topEdge:
            roundedCornersConfiguration = RoundedCornersConfiguration(
                topLeadingRadius: cornerRadius,
                topTrailingRadius: cornerRadius
            )
        case .bottomEdge:
            roundedCornersConfiguration = RoundedCornersConfiguration(
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius
            )
        case .all:
            roundedCornersConfiguration = RoundedCornersConfiguration(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: cornerRadius
            )
        case .none:
            roundedCornersConfiguration = nil
        }
    }
}

// MARK: - Constants

private extension TokenItemView {
    enum Constants {
        static let spacerLength = 12.0
    }
}

// MARK: - Auxiliary types

extension TokenItemView {
    enum RoundedCornersVerticalEdge {
        case topEdge
        case bottomEdge
        case all
    }

    private struct RoundedCornersConfiguration {
        var topLeadingRadius: CGFloat = 0.0
        var bottomLeadingRadius: CGFloat = 0.0
        var bottomTrailingRadius: CGFloat = 0.0
        var topTrailingRadius: CGFloat = 0.0
    }
}

// MARK: - Previews

struct TokenItemView_Previews: PreviewProvider {
    static let infoProvider: FakeTokenItemInfoProvider = {
        let walletManagers: [FakeWalletManager] = [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager]
        InjectedValues.setTokenQuotesRepository(FakeTokenQuotesRepository(walletManagers: walletManagers))
        return FakeTokenItemInfoProvider(walletManagers: walletManagers)
    }()

    static var previews: some View {
        VStack {
            VStack(spacing: 0) {
                TokenSectionView(title: "Ethereum network", topEdgeCornerRadius: nil)

                ForEach(infoProvider.viewModels, id: \.id) { model in
                    TokenItemView(viewModel: model, cornerRadius: 14, roundedCornersVerticalEdge: nil)
                }

                Spacer()
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
            .padding(16)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
