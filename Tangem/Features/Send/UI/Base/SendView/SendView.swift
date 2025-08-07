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
import TangemAccessibilityIdentifiers

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel
    let transitionService: SendTransitionService
    @Binding var interactiveDismissDisabled: Bool

    @Namespace private var namespace
    @FocusState private var focused: Bool

    @State private var bottomContainerMinY: CGFloat = 0
    @State private var contentMaxYBiggerThanContainerMinY: Bool = true

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let backgroundColor = Colors.Background.tertiary
    private let bottomGradientHeight: CGFloat = 150

    private var shouldShowHeader: Bool {
        viewModel.title != nil || viewModel.step.navigationLeadingViewType != nil || viewModel.step.navigationTrailingViewType != nil
    }

    var body: some View {
        VStack(spacing: 10) {
            headerView

            ZStack(alignment: .bottom) {
                currentPage
                    .focused($focused)
                    .allowsHitTesting(!viewModel.isUserInteractionDisabled)

                bottomOverlay
            }
            .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.step.type)
        }
        .onPreferenceChange(MaxYPreferenceKey.self) { maxY in
            contentMaxYBiggerThanContainerMinY = maxY > bottomContainerMinY
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                HideKeyboardButton(focused: $focused)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .scrollDismissesKeyboardCompat(.immediately)
        .safeAreaInset(edge: .bottom) {
            bottomContainer
        }
        .onReceive(viewModel.$isKeyboardActive, perform: { isKeyboardActive in
            focused = isKeyboardActive
        })
        .onChange(of: viewModel.shouldShowDismissAlert) { interactiveDismissDisabled = $0 }
        .navigationBarHidden(true)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    private var headerView: some View {
        if shouldShowHeader {
            ZStack(alignment: .center) {
                HStack {
                    leadingView

                    Spacer()

                    trailingView
                        .disabled(viewModel.trailingButtonDisabled)
                }

                headerText
            }
            .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.step.navigationTrailingViewType)
            .frame(height: 44)
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var leadingView: some View {
        switch viewModel.step.navigationLeadingViewType {
        case .none:
            EmptyView()
        case .closeButton:
            CloseButton(dismiss: viewModel.dismiss)
                .disabled(viewModel.closeButtonDisabled)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.closeButton)
        case .backButton:
            CircleButton(content: .icon(Assets.Glyphs.chevron20LeftButtonNew), action: viewModel.userDidTapBackButton)
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.step.navigationTrailingViewType {
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
    private var headerText: some View {
        switch viewModel.title {
        case .none:
            EmptyView()
        case .some(let title):
            VStack(spacing: 2) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .style(Fonts.BoldStatic.body, color: Colors.Text.primary1)
                    .accessibilityIdentifier(OnrampAccessibilityIdentifiers.title)

                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .style(Fonts.RegularStatic.caption1, color: Colors.Text.tertiary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .lineLimit(1)
            .infinityFrame(axis: .horizontal, alignment: .center)
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
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
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
                if viewModel.showBackButton {
                    SendViewBackButton(
                        backgroundColor: backButtonStyle.background(isDisabled: false),
                        cornerRadius: backButtonStyle.cornerRadius(for: backButtonSize),
                        height: backButtonSize.height,
                        action: viewModel.userDidTapBackButton
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                MainButton(
                    title: viewModel.mainButtonType.title(action: viewModel.flowActionType),
                    icon: viewModel.mainButtonType.icon(action: viewModel.flowActionType),
                    style: .primary,
                    size: .default,
                    isLoading: viewModel.mainButtonLoading,
                    isDisabled: !viewModel.actionIsAvailable,
                    action: viewModel.userDidTapActionButton
                )
            }
            .animation(SendTransitionService.Constants.auxiliaryViewAnimation, value: viewModel.showBackButton)
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
        .padding(.horizontal, 16)
        .readGeometry(\.frame, inCoordinateSpace: .global) { frame in
            bottomContainerMinY = frame.minY
        }
    }

    private var bottomOverlay: some View {
        LinearGradient(colors: [backgroundColor.opacity(0), backgroundColor], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .frame(maxHeight: bottomGradientHeight)
            .padding(.horizontal, 16)
            .allowsHitTesting(false)
            .opacity(shouldShowBottomOverlay ? 1 : 0)
            .animation(.default, value: shouldShowBottomOverlay)
    }

    private var shouldShowBottomOverlay: Bool {
        contentMaxYBiggerThanContainerMinY && viewModel.shouldShowBottomOverlay
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

// MARK: - Preview

/*
 struct SendView_Preview: PreviewProvider {
     static let card = FakeUserWalletModel.wallet3Cards

     static let viewModel = SendViewModel(
         walletName: card.userWalletName,
         walletModel: card.walletModelsManager.walletModels.first!,
         userWalletModel: card,
         transactionSigner: TransactionSignerMock(),
         sendType: .send,
         emailDataProvider: EmailDataProviderMock(),
         canUseFiatCalculation: true,
         coordinator: SendRoutableMock()
     )

     static var previews: some View {
         SendView(viewModel: viewModel)
             .previewDisplayName("Full screen")

         NavHolder()
             .sheet(isPresented: .constant(true)) {
                 SendView(viewModel: viewModel)
             }
             .previewDisplayName("Sheet")
     }
 }
 */
