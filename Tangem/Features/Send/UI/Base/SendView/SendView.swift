//
//  SendView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel
    @Binding var interactiveDismissDisabled: Bool

    @FocusState private var focused: Bool

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let bottomGradientHeight: CGFloat = 150

    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.Background.tertiary.ignoresSafeArea()

            currentPage
                // Important!!
                // When the currentPage has removal transition
                // It immediately disappears below `Colors.Background.tertiary.ignoresSafeArea()`
                // Because lost the `zIndex`
                .zIndex(1)
                .focused($focused)
                .allowsHitTesting(!viewModel.isUserInteractionDisabled)
                .transition(SendTransitions.transition)

            bottomOverlay
        }
        .animation(SendTransitions.animation, value: viewModel.step.type)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { leadingView }
            ToolbarItem(placement: .principal) { principalView }
            ToolbarItem(placement: .topBarTrailing) { trailingView }
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .bottom, spacing: .zero) { bottomContainer }
        .onReceive(viewModel.$isKeyboardActive, perform: { focused = $0 })
        .onChange(of: viewModel.shouldShowDismissAlert) { interactiveDismissDisabled = $0 }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    private var leadingView: some View {
        switch viewModel.navigationBarSettings.leadingViewType {
        case .none:
            EmptyView()

        case .closeButton:
            CloseButton(dismiss: viewModel.dismiss)
                .disabled(viewModel.closeButtonDisabled)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.closeButton)

        case .backButton:
            CircleButton.back(action: viewModel.userDidTapBackButton)
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.navigationBarSettings.trailingViewType {
        case .none:
            EmptyView()

        case .closeButton:
            CircleButton.close(action: viewModel.dismiss)
                .disabled(viewModel.closeButtonDisabled)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.closeButton)

        case .qrCodeButton(let action):
            Button(action: action) {
                Assets.qrCode.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.primary1)
            }

        case .dotsButton(let action):
            Button(action: action) {
                NavbarDotsImage()
            }
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.settingsButton)
        }
    }

    @ViewBuilder
    private var principalView: some View {
        switch viewModel.navigationBarSettings.title {
        case .none:
            EmptyView()
        case .some(let title):
            Text(title)
                .multilineTextAlignment(.center)
                .style(Fonts.BoldStatic.body, color: Colors.Text.primary1)
                .lineLimit(1)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.sendViewTitle)
        }
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step.type {
        case .destination(let sendDestinationViewModel):
            SendDestinationView(viewModel: sendDestinationViewModel)
                .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
                .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .amount(let sendAmountViewModel):
            SendAmountView(viewModel: sendAmountViewModel)
                .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
                .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .targets(let stakingTargetsViewModel):
            StakingTargetsView(viewModel: stakingTargetsViewModel)
                .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
                .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .summary(let sendSummaryViewModel):
            SendSummaryView(viewModel: sendSummaryViewModel)
                .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
                .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .onramp(let onrampViewModel):
            OnrampSummaryView(viewModel: onrampViewModel, keyboardActive: $focused)
                .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
                .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .finish(let sendFinishViewModel):
            SendFinishView(viewModel: sendFinishViewModel)
                .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
                .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        }
    }

    @ViewBuilder
    private var bottomContainer: some View {
        if let mainButtonType = viewModel.bottomBarSettings.action {
            MainButton(
                title: mainButtonType.title(action: viewModel.flowActionType),
                icon: mainButtonType.icon(action: viewModel.flowActionType, provider: viewModel.tangemIconProvider),
                style: .primary,
                size: .default,
                isLoading: viewModel.mainButtonLoading,
                isDisabled: !viewModel.actionIsAvailable,
                action: {
                    viewModel.userDidTapActionButton(mainButtonType: mainButtonType)
                }
            )
            .accessibilityIdentifier(SendAccessibilityIdentifiers.sendViewNextButton)
            .padding(.bottom, 14)
            .padding(.horizontal, 16)
        }
    }

    private var bottomOverlay: some View {
        ListFooterOverlayShadowView(opacities: [0, 0.95, 1])
            .frame(height: bottomGradientHeight)
            .visible(viewModel.shouldShowBottomOverlay)
    }
}
