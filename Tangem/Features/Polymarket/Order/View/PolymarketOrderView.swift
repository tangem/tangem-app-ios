//
//  PolymarketOrderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketOrderView: View {
    @ObservedObject private var viewModel: PolymarketOrderViewModel

    @FocusState private var isAmountFocused: Bool

    init(viewModel: PolymarketOrderViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: viewModel.screenTitle,
                onBack: viewModel.showsBack ? { viewModel.handleViewAction(.closeTapped) } : nil,
                onClose: { viewModel.handleViewAction(.closeTapped) }
            )
            .padding(.top, Constants.topBarTopPadding)

            content
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: .zero) { bottomContainer }
        .onWillAppear { viewModel.handleViewAction(.appeared) }
        .onWillDisappear { viewModel.handleViewAction(.disappeared) }
    }

    // MARK: - Bottom

    private var bottomContainer: some View {
        VStack(spacing: 0) {
            nextButton

            keyboardBar
        }
    }

    // MARK: - Content

    private var content: some View {
        GroupedScrollView(contentType: .plain(spacing: Constants.blockSpacing)) {
            PolymarketOrderMarketRow(model: viewModel.marketRow)

            PolymarketOrderAmountBlock(
                title: viewModel.amountTitle,
                payment: viewModel.payment,
                onAddFunds: viewModel.isAddFundsAvailable ? { viewModel.handleViewAction(.addFundsTapped) } : nil
            ) {
                VStack(spacing: Constants.captionSpacing) {
                    if viewModel.isAmountEditable {
                        amountField
                    } else {
                        proceedsAmount
                    }

                    amountCaption
                }
            } footer: {
                if !viewModel.isAmountEditable {
                    sellControls
                }
            }

            PolymarketOrderNotificationsView(notifications: viewModel.notifications)

            PolymarketOrderSlippageRow(
                valueText: viewModel.slippageText,
                onTap: { viewModel.handleViewAction(.slippageTapped) }
            )
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))

            if viewModel.isAwaitingFunds {
                PolymarketOrderNotificationsView(notifications: [.awaitingFunds])
            }
        }
        .horizontalPadding(Constants.horizontalPadding)
        .padding(.top, Constants.contentTopPadding)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeInOut(duration: Constants.notificationsAnimationDuration), value: viewModel.notifications)
        .animation(.easeInOut(duration: Constants.notificationsAnimationDuration), value: viewModel.isAwaitingFunds)
    }

    private var amountCaption: some View {
        captionContent
            .id(viewModel.amountCaption)
            .transition(.opacity)
            .frame(minHeight: viewModel.isAmountEditable ? 0 : Constants.captionMinHeight)
            .animation(.curve(.easeInOutRefined, duration: Constants.captionAnimationDuration), value: viewModel.amountCaption)
    }

    @ViewBuilder
    private var captionContent: some View {
        switch viewModel.amountCaption {
        case .toWin(let text):
            PolymarketAmountBadge.toWin(state: .value(text))
        case .shortfall(let text):
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                .multilineTextAlignment(.center)
        case nil:
            Color.clear
        }
    }

    private var amountField: some View {
        SendDecimalNumberTextField(viewModel: viewModel.fieldViewModel)
            .prefixSuffixOptions(viewModel.amountPrefixSuffixOptions)
            .appearance(.init(
                font: DesignSystem.Font.displayMediumToken.font,
                textColor: DesignSystem.Color.textPrimary,
                placeholderColor: DesignSystem.Color.textTertiary
            ))
            .alignment(.center)
            .minTextScale(Constants.amountMinTextScale)
            .focused($isAmountFocused)
    }

    private var proceedsAmount: some View {
        VStack(spacing: Constants.captionSpacing) {
            proceedsValue

            if let sellingText = viewModel.sellingText {
                Text(sellingText)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.contentFrameUpdate, value: sellingText)
            }
        }
    }

    @ViewBuilder
    private var proceedsValue: some View {
        if viewModel.isProceedsLoading {
            Shimmer()
                .frame(width: Constants.proceedsSkeletonWidth, height: Constants.proceedsSkeletonHeight)
                .clipShape(Capsule())
                .frame(height: Constants.proceedsLineHeight)
        } else {
            Text(viewModel.proceedsText)
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .contentTransition(.numericText())
                .opacity(viewModel.isProceedsStale ? Constants.staleOpacity : 1)
                .animation(.curve(.easeInOutRefined, duration: Constants.staleAnimationDuration), value: viewModel.isProceedsStale)
                .animation(.contentFrameUpdate, value: viewModel.proceedsText)
        }
    }

    private var sellControls: some View {
        HStack(spacing: Constants.sellControlsSpacing) {
            ForEach(viewModel.amountFractions, id: \.self) { fraction in
                sellControl(minWidth: Constants.chipMinWidth) {
                    Text(fraction.title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                } action: {
                    viewModel.handleViewAction(.fractionTapped(fraction))
                }
                .frame(maxWidth: .infinity)
            }

            stepButton(DesignSystem.Icons.SignMinus.regular20, step: -1, label: Constants.decreaseAccessibilityLabel)

            stepButton(DesignSystem.Icons.SignPlus.regular20, step: 1, label: Constants.increaseAccessibilityLabel)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.bottom, Constants.sellControlsBottomPadding)
    }

    private func stepButton(_ icon: ImageType, step: Int, label: String) -> some View {
        sellControl(minWidth: Constants.controlSide) {
            icon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.stepIconSide, height: Constants.stepIconSide)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        } action: {
            viewModel.handleViewAction(.stepTapped(step))
        }
        .frame(width: Constants.controlSide)
        .accessibilityLabel(label)
    }

    private func sellControl(
        minWidth: CGFloat,
        @ViewBuilder label: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        SwiftUI.Button(action: action) {
            label()
                .frame(minWidth: minWidth, minHeight: Constants.controlSide)
                .background(DesignSystem.Color.bgTransparentPrimary, in: Capsule())
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Keyboard bar

    @ViewBuilder
    private var keyboardBar: some View {
        if isAmountFocused {
            PolymarketAmountFractionChips(
                fractions: viewModel.amountFractions,
                focused: $isAmountFocused,
                onSelect: { viewModel.handleViewAction(.fractionTapped($0)) }
            )
            .transition(.opacity)
        }
    }

    private var nextButton: some View {
        TangemUI.Button(
            label: viewModel.nextButtonTitle,
            accessibilityLabel: viewModel.nextButtonTitle,
            action: {
                isAmountFocused = false
                viewModel.handleViewAction(.nextTapped)
            }
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isNextEnabled)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.buttonTopPadding)
        .padding(.bottom, Constants.buttonBottomPadding)
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

// MARK: - Constants

private extension PolymarketOrderView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let amountMinTextScale: CGFloat = 0.5
        static let horizontalPadding: CGFloat = 16
        static let sellControlsSpacing: CGFloat = 4
        static let chipMinWidth: CGFloat = 56
        // [REDACTED_TODO_COMMENT]
        static let decreaseAccessibilityLabel = "Decrease"
        // [REDACTED_TODO_COMMENT]
        static let increaseAccessibilityLabel = "Increase"

        static let controlSide: CGFloat = 36
        static let stepIconSide: CGFloat = 20
        static let proceedsSkeletonWidth: CGFloat = 140
        static let proceedsSkeletonHeight: CGFloat = 44
        static let proceedsLineHeight: CGFloat = 52
        static let staleOpacity: CGFloat = 0.4
        static let captionMinHeight: CGFloat = 24
        static let captionAnimationDuration: TimeInterval = 0.2
        static let staleAnimationDuration: TimeInterval = 0.2
        static let sellControlsBottomPadding: CGFloat = 8
        static let contentTopPadding: CGFloat = 16
        static let blockSpacing: CGFloat = 8
        static let captionSpacing: CGFloat = 8
        static let buttonTopPadding: CGFloat = 12
        static let buttonBottomPadding: CGFloat = 12
        static let notificationsAnimationDuration: TimeInterval = 0.3
        static let cornerRadius: CGFloat = 24
    }
}
