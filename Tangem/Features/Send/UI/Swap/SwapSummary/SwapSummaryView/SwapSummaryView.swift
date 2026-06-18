//
//  SwapSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

struct SwapSummaryView: View {
    @ObservedObject var viewModel: SwapSummaryViewModel
    @FocusState.Binding var keyboardActive: Bool

    @State private var shouldRestoreKeyboard = true
    @State private var viewGeometryInfo: GeometryInfo = .zero
    @State private var contentSize: CGSize = .zero
    @State private var bottomViewSize: CGSize = .zero

    private var spacer: CGFloat {
        var height = viewGeometryInfo.frame.height
        height += viewGeometryInfo.safeAreaInsets.bottom
        height -= viewGeometryInfo.safeAreaInsets.top
        height -= contentSize.height
        height -= bottomViewSize.height
        return max(0, height)
    }

    var body: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea(.all)

            GroupedScrollView(contentType: .lazy()) {
                VStack(spacing: 14) {
                    SwapAmountView(viewModel: viewModel.swapAmountViewModel)

                    providerSectionView

                    feeSectionView

                    informationSection
                }
                .readGeometry(\.frame.size, bindTo: $contentSize)

                bottomView
            }
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.title)
            .scrollDismissesKeyboard(.immediately)
        }
        .keyboardToolbar(toolbarContent)
        .keyboardAutoHide(
            isActive: $keyboardActive,
            onInput: viewModel.swapAmountViewModel.sourceDecimalNumberTextFieldViewModel.valuePublisher()
        )
        .readGeometry(bindTo: $viewGeometryInfo)
        .ignoresSafeArea(.keyboard)
        .onChange(of: viewModel.swapAmountViewModel.isInputDisabled) { isDisabled in
            if isDisabled {
                shouldRestoreKeyboard = keyboardActive
                keyboardActive = false
            } else if shouldRestoreKeyboard {
                keyboardActive = true
            }
        }
    }

    // MARK: - Provider

    @ViewBuilder
    private var providerSectionView: some View {
        let isDetailed = viewModel.formVariant == .detailed
        let isSimple = viewModel.formVariant == .simple

        // Both views always rendered. Mode switch flips frame/opacity only — no
        // conditional add/remove, so SwapSummaryProviderView's
        // `.transition(.opacity.animation(.easeInOut))` does not fire on toggle.
        if viewModel.swapSummaryProviderViewModel.providerState != nil {
            VStack(spacing: 0) {
                SwapSummaryProviderView(viewModel: viewModel.swapSummaryProviderViewModel)
                    .frame(maxHeight: isDetailed ? .infinity : 0)
                    .opacity(isDetailed ? 1 : 0)
                    .clipped()
                    .accessibilityHidden(!isDetailed)

                SwapSummaryProviderCompactView(
                    viewModel: viewModel.swapSummaryProviderViewModel,
                    shouldAnimateBestRateBadge: $viewModel.shouldAnimateBestRateBadge
                )
                .frame(maxHeight: isSimple ? .infinity : 0)
                .opacity(isSimple ? 1 : 0)
                .clipped()
                .accessibilityHidden(!isSimple)
            }
        }
    }

    // MARK: - Fee

    @ViewBuilder
    private var feeSectionView: some View {
        SendFeeCompactView(viewModel: viewModel.feeCompactViewModel, tapAction: {
            keyboardActive = false
            viewModel.userDidTapFee()
        })
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.feeBlock)
    }

    private var informationSection: some View {
        ForEach(viewModel.notificationInputs) {
            NotificationView(input: $0)
                .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
                .transition(.notificationTransition)
        }
    }

    private var bottomView: some View {
        VStack(spacing: 12) {
            FixedSpacer(height: spacer)

            VStack(spacing: 12) {
                legalView

                mainButton
            }
            .readGeometry(\.frame.size, bindTo: $bottomViewSize)
        }
        .disableAnimations() // To force `.animation(nil)` behavior
    }

    @ViewBuilder
    private var mainButton: some View {
        if viewModel.mainButtonIsUpdating {
            mainActionButton(isLoading: true)
        } else if viewModel.mainButtonNeedsHold {
            mainHoldActionButton
        } else {
            mainActionButton(isLoading: viewModel.mainButtonIsLoading)
        }
    }

    private func mainActionButton(isLoading: Bool) -> some View {
        MainButton(
            title: viewModel.mainButtonState.title,
            icon: viewModel.mainButtonIcon,
            isLoading: isLoading,
            isDisabled: !viewModel.mainButtonIsEnabled,
            action: viewModel.userDidTapMainActionButton
        )
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.confirmButton)
    }

    private var mainHoldActionButton: some View {
        HoldToConfirmButton(
            title: viewModel.mainButtonState.title,
            isLoading: viewModel.mainButtonIsLoading,
            isDisabled: !viewModel.mainButtonIsEnabled,
            action: viewModel.userDidTapMainActionButton
        )
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.confirmButton)
    }

    @ViewBuilder
    private var legalView: some View {
        if let legalText = viewModel.transactionDescription {
            Text(legalText)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var toolbarContent: some View {
        chipsToolbarContent
    }

    @ViewBuilder
    private var chipsToolbarContent: some View {
        if #available(iOS 26.0, *) {
            glassChipsToolbarContent
        } else {
            regularChipsToolbarContent
        }
    }

    private var visibleAmountFractions: [SwapAmountFraction] {
        guard !viewModel.areAmountFractionsHidden else {
            return []
        }

        return SwapAmountFraction.allCases.filter { !viewModel.isMaxAmountButtonHidden || $0 != .max }
    }

    private var regularChipsToolbarContent: some View {
        HStack(spacing: 8) {
            ForEach(visibleAmountFractions, id: \.self) { fraction in
                Button {
                    viewModel.userDidTapAmountFraction(fraction)
                } label: {
                    Text(fraction.title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Capsule().fill(Colors.Button.secondary))
                }
                .accessibilityIdentifier(SwapAccessibilityIdentifiers.amountFraction(fraction.accessibilityIdentifierToken))
            }

            // Without fraction chips the lone dismiss button would be centered, so pin it to the trailing edge.
            if visibleAmountFractions.isEmpty {
                Spacer(minLength: .zero)
            }

            Button(action: { keyboardActive = false }) {
                keyboardSFSymbol
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Colors.Button.secondary))
            }
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.keyboardDismissButton)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
    }

    @available(iOS 26.0, *)
    private var glassChipsToolbarContent: some View {
        HStack(spacing: 8) {
            ForEach(visibleAmountFractions, id: \.self) { fraction in
                Button {
                    viewModel.userDidTapAmountFraction(fraction)
                } label: {
                    Text(fraction.title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .glassEffect(.regular.interactive())
                .glassEffectTransition(.materialize)
                .accessibilityIdentifier(SwapAccessibilityIdentifiers.amountFraction(fraction.accessibilityIdentifierToken))
            }

            // Without fraction chips the lone dismiss button would be centered, so pin it to the trailing edge.
            if visibleAmountFractions.isEmpty {
                Spacer(minLength: .zero)
            }

            Button(action: { keyboardActive = false }) {
                keyboardSFSymbol
                    .frame(width: 36, height: 36)
            }
            .glassEffect(.regular.interactive(), in: Circle())
            .glassEffectTransition(.materialize)
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.keyboardDismissButton)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
    }

    private var keyboardSFSymbol: some View {
        Image(systemName: "keyboard.chevron.compact.down")
            .style(Fonts.Bold.callout, color: Colors.Icon.primary1)
    }
}
