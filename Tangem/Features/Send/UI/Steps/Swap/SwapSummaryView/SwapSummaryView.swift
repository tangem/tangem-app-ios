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

                    providerSection

                    feeSectionView

                    informationSection
                }
                .readGeometry(\.frame.size, bindTo: $contentSize)

                bottomView
            }
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.title)
            .scrollDismissesKeyboard(.immediately)
        }
        .keyboardToolbar(keyboardToolbarContent)
        .readGeometry(bindTo: $viewGeometryInfo)
        .ignoresSafeArea(.keyboard)
        /*
         .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
         .toolbar {
             NavigationToolbarButton
                 .close(placement: .topBarTrailing, action: viewModel.didTapCloseButton)
         }
         .keyboardToolbar(keyboardToolbarContent)
         .onAppear { isFocused = true }
         .focused($isFocused)
         .ignoresSafeArea(.keyboard)
         .alert(item: $viewModel.alert) { $0.alert }
         // For animate button below informationSection
         .animation(.easeInOut, value: viewModel.providerState?.id)
         .animation(.default, value: viewModel.notificationInputs)
          */
    }

    // MARK: - Fee

    @ViewBuilder
    private var feeSectionView: some View {
        SendFeeCompactView(viewModel: viewModel.feeCompactViewModel, tapAction: viewModel.userDidTapFee)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.feeBlock)
    }

//    private var swappingViews: some View {
//        VStack(spacing: 14) {
//            GroupedSection(viewModel.swapSourceTokenViewModel) {
//                SwapSourceTokenView(viewModel: $0)
//                    .didTapChangeCurrency(viewModel.userDidTapChangeSourceTokenButton)
//                    .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
//            }
//
//            GroupedSection(viewModel.swapReceiveTokenViewModel) {
//                SwapReceiveTokenView(viewModel: $0)
//                    .didTapChangeCurrency(viewModel.userDidTapChangeReceiveTokenButton)
//                    .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
//            }
//            .innerContentPadding(12)
//            .backgroundColor(Colors.Background.action)
//        }
//        .overlay(alignment: .center) { swappingButton }
//        .padding(.top, 10) // Check it
//    }
//
//    private var swappingButton: some View {
//        Button(action: viewModel.userDidTapSwapSourceAndReceiveTokensButton) {
//            if viewModel.isSwapButtonLoading {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
//            } else {
//                Assets.swappingIcon.image
//                    .renderingMode(.template)
//                    .resizable()
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(viewModel.isSwapButtonDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
//            }
//        }
//        .disabled(viewModel.isSwapButtonLoading || viewModel.isSwapButtonDisabled)
//        .frame(width: 44, height: 44)
//        .background(Colors.Background.primary)
//        .cornerRadius(22)
//        .overlay(
//            RoundedRectangle(cornerRadius: 22)
//                .stroke(Colors.Stroke.primary, lineWidth: 1)
//        )
//    }

    private var informationSection: some View {
        ForEach(viewModel.notificationInputs) {
            NotificationView(input: $0)
                .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
                .transition(.notificationTransition)
        }
    }

//    [REDACTED_USERNAME]
//    private var feeSection: some View {
//        if let expressFeeRowViewModel = viewModel.expressFeeRowViewModel {
//            FeeCompactView(viewModel: expressFeeRowViewModel, tapAction: viewModel.userDidTapFee)
//                .accessibilityIdentifier(SwapAccessibilityIdentifiers.feeBlock)
//        }
//    }

    private var providerSection: some View {
        GroupedSection(viewModel.providerState) { state in
            switch state {
            case .loading:
                LoadingProvidersRow()
            case .loaded(let data):
                ProviderRowView(viewModel: data)
            }
        }
        .innerContentPadding(12)
        .backgroundColor(Colors.Background.action)
    }

    private var bottomView: some View {
        VStack(spacing: 12) {
            FixedSpacer(height: spacer)

            VStack(spacing: 12) {
                legalView

                MainButton(
                    title: viewModel.mainButtonState.title,
                    icon: viewModel.mainButtonIcon,
                    isLoading: viewModel.mainButtonIsLoading,
                    isDisabled: !viewModel.mainButtonIsEnabled,
                    action: viewModel.userDidTapMainActionButton
                )
            }
            .readGeometry(\.frame.size, bindTo: $bottomViewSize)
        }
        .disableAnimations() // To force `.animation(nil)` behavior
    }

    @ViewBuilder
    private var legalView: some View {
        if let legalText = viewModel.transactionDescription {
            Text(legalText)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var keyboardToolbarContent: some View {
        if #available(iOS 26.0, *) {
            glassToolbarContent
        } else {
            regularToolbarContent
        }
    }

    @available(iOS 26.0, *)
    private var glassToolbarContent: some View {
        HStack(spacing: .zero) {
            if !viewModel.isMaxAmountButtonHidden {
                Button(action: viewModel.userDidTapMaxAmount) {
                    Text(Localization.sendMaxAmountLabel)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .contentShape(.rect)
                }
                .glassEffect(.regular.interactive())
                .glassEffectTransition(.materialize)
            }

            Spacer()

            Button(action: { keyboardActive = false }) {
                keyboardSFSymbol
                    .frame(width: 50, height: 50)
                    .contentShape(Circle())
            }
            .glassEffect(.regular.interactive(), in: Circle())
            .glassEffectTransition(.materialize)
        }
        .padding(.horizontal, 20)
    }

    private var regularToolbarContent: some View {
        HStack(spacing: .zero) {
            if !viewModel.isMaxAmountButtonHidden {
                Button(action: viewModel.userDidTapMaxAmount) {
                    Text(Localization.sendMaxAmountLabel)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                        .padding(.horizontal, 20)
                        .frame(height: 40)
                        .contentShape(.rect)
                }
            }

            Spacer()

            Button(action: { keyboardActive = false }) {
                keyboardSFSymbol
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .contentShape(.rect)
            }
        }
    }

    private var keyboardSFSymbol: some View {
        Image(systemName: "keyboard.chevron.compact.down")
            .style(Fonts.Bold.callout, color: Colors.Icon.primary1)
    }
}
