//
//  MarketsPortfolioTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsPortfolioTokenItemView: View {
    @ObservedObject var viewModel: MarketsPortfolioTokenItemViewModel

    let isExpanded: Bool
    @State private var textBlockSize: CGSize = .zero

    var body: some View {
        CustomDisclosureGroup(isExpanded: isExpanded) {
            viewModel.showContextActions()
        } prompt: {
            tokenView
        } expandedView: {
            quickActionsView
        }
    }

    private var tokenView: some View {
        HStack(spacing: 12) {
            TokenItemViewLeadingComponent(
                name: viewModel.tokenIconName,
                imageURL: viewModel.imageURL,
                customTokenColor: viewModel.customTokenColor,
                blockchainIconAsset: viewModel.blockchainIconAsset,
                hasMonochromeIcon: viewModel.hasMonochromeIcon,
                isCustom: viewModel.isCustom,
                networkBorderColor: Colors.Background.action
            )

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(viewModel.name)
                            .style(
                                Fonts.Bold.subheadline,
                                color: viewModel.hasError ? Colors.Text.tertiary : Colors.Text.primary1
                            )
                            .lineLimit(1)

                        if viewModel.hasPendingTransactions {
                            ProgressDots(style: .small)
                        }
                    }
                    .frame(minWidth: 0.3 * textBlockSize.width, alignment: .leading)

                    Spacer(minLength: 8)

                    if viewModel.hasError, let errorMessage = viewModel.errorMessage {
                        // Need for define size overlay view
                        Text(errorMessage)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            .hidden(true)
                    } else {
                        LoadableTokenBalanceView(
                            state: viewModel.balanceFiat,
                            style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                            loader: .init(size: .init(width: 40, height: 12))
                        )
                        .layoutPriority(3)
                    }
                }

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 6, content: {
                        Text(viewModel.description)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            .layoutPriority(1)
                    })
                    .frame(minWidth: 0.32 * textBlockSize.width, alignment: .leading)
                    .layoutPriority(2)

                    Spacer(minLength: Constants.spacerLength)

                    if !viewModel.hasError {
                        LoadableTokenBalanceView(
                            state: viewModel.balanceCrypto,
                            style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                            loader: .init(size: .init(width: 40, height: 12))
                        )
                        .layoutPriority(3)
                    }
                }
            }
            .overlay(overlayView)
            .readGeometry(\.size, onChange: { newValue in
                withAnimation(nil) {
                    textBlockSize = newValue
                }
            })
        }
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var overlayView: some View {
        if viewModel.hasError, let errorMessage = viewModel.errorMessage {
            HStack {
                Spacer()

                Text(errorMessage)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }

    private var quickActionsView: some View {
        VStack(spacing: .zero) {
            ForEach(indexed: viewModel.contextActions.indexed()) { index, action in
                VStack(alignment: .leading, spacing: .zero) {
                    // It is necessary to draw the indentation with a strip
                    makeLineRowActionItem()

                    // Directly in the view of the fastest action
                    Button {
                        viewModel.didTapContextAction(action)
                    } label: {
                        makeQuickActionItem(for: action, at: index)
                    }

                    // Lower indentation
                    if index == (viewModel.contextActions.count - 1) {
                        FixedSpacer(width: 12)
                    }
                }
            }
        }
        .offset(y: -12) // Required within the design
    }

    private func makeQuickActionItem(for actionType: TokenActionType, at index: Int) -> some View {
        MarketsActionRowView(
            icon: portfolioTokenActionTypeImageType(for: actionType),
            title: actionType.title,
            subtitle: actionType.description,
            showNotificationBadge: viewModel.shouldShowUnreadNotificationBadge(for: actionType),
            style: .solid
        )
    }

    private func makeLineRowActionItem() -> some View {
        HStack(alignment: .center) {
            FixedSpacer(width: 18)

            Rectangle()
                .fill(Colors.Stroke.primary)
                .frame(width: 1, height: 16)
                .padding(.vertical, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func portfolioTokenActionTypeImageType(for type: TokenActionType) -> ImageType {
        switch type {
        case .buy:
            return Assets.Portfolio.buy12
        case .exchange:
            return Assets.Portfolio.exchange12
        case .receive:
            return Assets.Portfolio.receive12
        case .stake:
            return Assets.Portfolio.stake12
        case .yield:
            return Assets.YieldModule.yieldSupplyAssets
        default:
            assertionFailure("Unhandled TokenActionType: \(type)")
            return Assets.Portfolio.buy12
        }
    }
}

private extension MarketsPortfolioTokenItemView {
    enum Constants {
        static let spacerLength = 8.0
    }
}
