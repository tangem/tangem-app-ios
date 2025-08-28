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
    let transitionService: SendTransitionService
    @Binding var interactiveDismissDisabled: Bool

    @Namespace private var namespace
    @FocusState private var focused: Bool

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let bottomGradientHeight: CGFloat = 150

    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.Background.tertiary.ignoresSafeArea()

            currentPage
                .focused($focused)
                .allowsHitTesting(!viewModel.isUserInteractionDisabled)

            bottomOverlay
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { leadingView }
            ToolbarItem(placement: .principal) { principalView }
            ToolbarItem(placement: .topBarTrailing) { trailingView }
            ToolbarItem(placement: .keyboard) { keyboardToolbarView }
        }
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.step.type)
        .animation(.none, value: viewModel.navigationBarSettings)
        .animation(.none, value: viewModel.bottomBarSettings)
        .scrollDismissesKeyboardCompat(.immediately)
        .safeAreaInset(edge: .bottom) { bottomContainer }
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
            VStack(spacing: 2) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .style(Fonts.BoldStatic.body, color: Colors.Text.primary1)
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.sendViewTitle)

                if let subtitle = viewModel.navigationBarSettings.subtitle {
                    Text(subtitle)
                        .style(Fonts.RegularStatic.caption1, color: Colors.Text.tertiary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .lineLimit(1)
        }
    }

    @ViewBuilder
    private var keyboardToolbarView: some View {
        if viewModel.bottomBarSettings.keyboardHiddenToolbarButtonVisible {
            HStack(spacing: .zero) {
                Spacer()

                HideKeyboardButton(focused: $focused)
            }
            .infinityFrame(axis: .horizontal)
        }
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step.type {
        case .destination(let sendDestinationViewModel):
            SendDestinationView(
                viewModel: sendDestinationViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .newDestination(let sendDestinationViewModel):
            SendNewDestinationView(
                viewModel: sendDestinationViewModel,
                transitionService: transitionService
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .amount(let sendAmountViewModel):
            SendAmountView(
                viewModel: sendAmountViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .newAmount(let sendAmountViewModel):
            SendNewAmountView(
                viewModel: sendAmountViewModel,
                transitionService: transitionService
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .fee(let sendFeeViewModel):
            SendFeeView(
                viewModel: sendFeeViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .validators(let stakingValidatorsViewModel):
            StakingValidatorsView(
                viewModel: stakingValidatorsViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .summary(let sendSummaryViewModel):
            SendSummaryView(
                viewModel: sendSummaryViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .newSummary(let sendSummaryViewModel):
            SendNewSummaryView(
                viewModel: sendSummaryViewModel,
                transitionService: transitionService
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .onramp(let onrampViewModel):
            OnrampView(
                viewModel: onrampViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames()),
                keyboardActive: $focused
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .finish(let sendFinishViewModel):
            SendFinishView(
                viewModel: sendFinishViewModel,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        case .newFinish(let sendFinishViewModel):
            SendNewFinishView(
                viewModel: sendFinishViewModel,
                transitionService: transitionService
            )
            .onAppear { [step = viewModel.step] in viewModel.onAppear(newStep: step) }
            .onDisappear { [step = viewModel.step] in viewModel.onDisappear(oldStep: step) }
        }
    }

    @ViewBuilder
    private var bottomContainer: some View {
        VStack(spacing: 10) {
            if let url = viewModel.transactionURL, viewModel.shouldShowShareExploreButtons {
                HStack(spacing: 8) {
                    MainButton(
                        title: Localization.commonExplore,
                        icon: .leading(Assets.Glyphs.explore),
                        style: .secondary,
                        action: { viewModel.explore(url: url) }
                    )
                    MainButton(
                        title: Localization.commonShare,
                        icon: .leading(Assets.share),
                        style: .secondary,
                        action: { viewModel.share(url: url) }
                    )
                }
                .transition(.opacity.animation(SendTransitionService.Constants.newAnimation))
            }

            HStack(spacing: 8) {
                if viewModel.bottomBarSettings.backButtonVisible {
                    SendViewBackButton(
                        backgroundColor: backButtonStyle.background(isDisabled: false),
                        cornerRadius: backButtonStyle.cornerRadius(for: backButtonSize),
                        height: backButtonSize.height,
                        action: viewModel.userDidTapBackButton
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                MainButton(
                    title: viewModel.bottomBarSettings.action.title(action: viewModel.flowActionType),
                    icon: viewModel.bottomBarSettings.action.icon(action: viewModel.flowActionType),
                    style: .primary,
                    size: .default,
                    isLoading: viewModel.mainButtonLoading,
                    isDisabled: !viewModel.actionIsAvailable,
                    action: viewModel.userDidTapActionButton
                )
                .accessibilityIdentifier(SendAccessibilityIdentifiers.sendViewNextButton)
            }
            .animation(SendTransitionService.Constants.auxiliaryViewAnimation, value: viewModel.bottomBarSettings.backButtonVisible)
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
        .padding(.horizontal, 16)
    }

    private var bottomOverlay: some View {
        ListFooterOverlayShadowView()
            .frame(height: bottomGradientHeight)
            .visible(viewModel.shouldShowBottomOverlay)
    }
}

// MARK: - Back button

private struct SendViewBackButton: View {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            backgroundColor
                .cornerRadiusContinuous(cornerRadius)
                .overlay(
                    Assets.arrowLeftMini
                        .image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.primary1)
                )
                .frame(size: CGSize(bothDimensions: height))
        }
    }
}
