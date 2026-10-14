//
//  PolymarketBalanceBlockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketBalanceBlockView: View {
    @ObservedObject var viewModel: PolymarketBalanceBlockViewModel

    var body: some View {
        balanceBlock
            .polymarketStateTransition(viewModel.isBalanceLoading)
            .bindAlert($viewModel.alert)
    }
}

// MARK: - Balance

private extension PolymarketBalanceBlockView {
    @ViewBuilder
    var balanceBlock: some View {
        if viewModel.isBalanceLoading {
            balanceBlockSkeleton
        } else {
            VStack(spacing: Constants.balanceSpacing) {
                balanceSelector

                balanceAmount

                actionButtons
                    .padding(.top, Constants.actionButtonsTopPadding)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Constants.actionButtonsBottomPadding)
        }
    }

    var balanceBlockSkeleton: some View {
        VStack(spacing: Constants.balanceSpacing) {
            Shimmer().variant(.text(style: .subheading, alignment: .center))

            skeleton(
                width: Constants.skeletonAmountWidth,
                height: Constants.skeletonAmountHeight,
                cornerRadius: Constants.skeletonAmountHeight / 2
            )
            .padding(.vertical, Constants.balanceSpacing)

            HStack(spacing: Constants.actionButtonsSpacing) {
                ForEach(0 ..< Constants.skeletonActionCount, id: \.self) { _ in
                    VStack(spacing: Constants.skeletonActionSpacing) {
                        skeleton(
                            width: TangemMainActionButton.Size.buttonSide,
                            height: TangemMainActionButton.Size.buttonSide,
                            cornerRadius: TangemMainActionButton.Size.buttonSide / 2
                        )

                        Shimmer().variant(.text(style: .subheading, alignment: .center))
                    }
                    .frame(minWidth: Constants.actionWidth)
                }
            }
            .padding(.top, Constants.actionButtonsTopPadding)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Constants.actionButtonsBottomPadding)
    }

    func skeleton(width: CGFloat, height: CGFloat, cornerRadius: CGFloat? = nil) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(.rect(cornerRadius: cornerRadius ?? height / 2, style: .continuous))
    }

    var balanceAmount: some View {
        LoadableBalanceView(
            state: viewModel.balance,
            style: .init(font: DesignSystem.Font.displayMediumToken, textColor: DesignSystem.Color.textPrimary),
            loader: .init(size: Constants.balanceLoaderSize)
        )
        .padding(.trailing, Constants.balanceAmountTrailingPadding)
        .id(viewModel.balanceMode)
        .transition(.opacity)
    }

    var balanceSelector: some View {
        SwiftUI.Button {
            withAnimation(.easeInOut(duration: Constants.balanceModeAnimationDuration)) {
                viewModel.handleViewAction(.toggleBalanceMode)
            }
        } label: {
            HStack(spacing: Constants.balanceSelectorSpacing) {
                Text(viewModel.balanceModeTitle)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .id(viewModel.balanceMode)
                    .transition(.opacity)

                DesignSystem.Icons.ChevronDoubleVertical.regular16.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: Constants.selectorIconSize))
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSwitchBalanceMode)
    }

    var actionButtons: some View {
        HStack(spacing: Constants.actionButtonsSpacing) {
            TangemMainActionButton(
                title: Localization.commonAddFunds,
                icon: Assets.DesignSystem.arrowDown,
                action: { viewModel.handleViewAction(.openAddFunds) },
                reasonTapWhenDisabled: { viewModel.handleViewAction(.openAddFunds) }
            )
            .frame(minWidth: Constants.actionWidth)
            .disabled(!viewModel.isAddFundsEnabled)
            .accessibilityIdentifier(PolymarketAccessibilityIdentifiers.addFundsButton)

            TangemMainActionButton(
                title: Localization.predictionMainWithdraw,
                icon: Assets.DesignSystem.arrowUp,
                action: { viewModel.handleViewAction(.openWithdraw) },
                reasonTapWhenDisabled: { viewModel.handleViewAction(.openWithdraw) }
            )
            .frame(minWidth: Constants.actionWidth)
            .disabled(!viewModel.isWithdrawEnabled)
            .accessibilityIdentifier(PolymarketAccessibilityIdentifiers.withdrawButton)
        }
        .animation(.default, value: viewModel.isAddFundsEnabled)
        .animation(.default, value: viewModel.isWithdrawEnabled)
    }
}

// MARK: - Constants

private extension PolymarketBalanceBlockView {
    enum Constants {
        static let balanceSpacing: CGFloat = 4
        static let balanceAmountTrailingPadding: CGFloat = 4
        static let balanceLoaderSize = CGSize(width: 160, height: 40)

        static let skeletonAmountWidth: CGFloat = 170
        static let skeletonAmountHeight: CGFloat = 44
        static let skeletonActionCount = 2
        static let skeletonActionSpacing: CGFloat = 8
        static let balanceSelectorSpacing: CGFloat = 4
        static let selectorIconSize: CGFloat = 16
        static let balanceModeAnimationDuration: TimeInterval = 0.2
        static let actionButtonsSpacing: CGFloat = 0
        static let actionButtonsTopPadding: CGFloat = 28
        static let actionButtonsBottomPadding: CGFloat = 24
        static let actionWidth: CGFloat = 102
    }
}
