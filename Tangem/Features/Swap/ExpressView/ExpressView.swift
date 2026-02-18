//
//  ExpressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct ExpressView: View {
    @ObservedObject private var viewModel: ExpressViewModel

    @State private var viewGeometryInfo: GeometryInfo = .zero
    @State private var contentSize: CGSize = .zero
    @State private var bottomViewSize: CGSize = .zero

    @FocusState private var isFocused: Bool

    private var spacer: CGFloat {
        var height = viewGeometryInfo.frame.height
        height += viewGeometryInfo.safeAreaInsets.bottom
        height -= viewGeometryInfo.safeAreaInsets.top
        height -= contentSize.height
        height -= bottomViewSize.height
        return max(0, height)
    }

    init(viewModel: ExpressViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea(.all)

            GroupedScrollView(contentType: .lazy(alignment: .center, spacing: .zero)) {
                VStack(spacing: 14) {
                    swappingViews

                    providerSection

                    feeSection

                    informationSection
                }
                .readGeometry(\.frame.size, bindTo: $contentSize)

                bottomView
            }
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.title)
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
        .toolbar {
            NavigationToolbarButton
                .close(placement: .topBarTrailing, action: viewModel.didTapCloseButton)
        }
        .keyboardToolbar(keyboardToolbarContent)
        .onAppear { isFocused = true }
        .focused($isFocused)
        .readGeometry(bindTo: $viewGeometryInfo)
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.alert) { $0.alert }
        // For animate button below informationSection
        .animation(.easeInOut, value: viewModel.providerState?.id)
        .animation(.default, value: viewModel.notificationInputs)
    }

    private var swappingViews: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 14) {
                GroupedSection(viewModel.sendCurrencyViewModel) {
                    SendCurrencyView(viewModel: $0)
                        .didTapChangeCurrency(viewModel.userDidTapChangeSourceButton)
                        .accessibilityIdentifier(SwapAccessibilityIdentifiers.fromAmountTextField)
                }
                .innerContentPadding(12)
                .backgroundColor(Colors.Background.action)

                GroupedSection(viewModel.receiveCurrencyViewModel) {
                    ReceiveCurrencyView(viewModel: $0)
                        .didTapChangeCurrency(viewModel.userDidTapChangeDestinationButton)
                        .didTapNetworkFeeInfoButton(viewModel.userDidTapPriceChangeInfoButton)
                        .accessibilityIdentifier(SwapAccessibilityIdentifiers.toAmountTextField)
                }
                .innerContentPadding(12)
                .backgroundColor(Colors.Background.action)
            }

            swappingButton
        }
        .padding(.top, 10)
    }

    private var swappingButton: some View {
        Button(action: viewModel.userDidTapSwapSwappingItemsButton) {
            if viewModel.isSwapButtonLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
            } else {
                Assets.swappingIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(viewModel.isSwapButtonDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
            }
        }
        .disabled(viewModel.isSwapButtonLoading || viewModel.isSwapButtonDisabled)
        .frame(width: 44, height: 44)
        .background(Colors.Background.primary)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }

    private var informationSection: some View {
        ForEach(viewModel.notificationInputs) {
            NotificationView(input: $0)
                .setButtonsLoadingState(to: viewModel.isSwapButtonLoading)
                .transition(.notificationTransition)
        }
    }

    @ViewBuilder
    private var feeSection: some View {
        if let expressFeeRowViewModel = viewModel.expressFeeRowViewModel {
            FeeCompactView(viewModel: expressFeeRowViewModel) {
                viewModel.userDidTapFeeRow()
            }
            .accessibilityIdentifier(SwapAccessibilityIdentifiers.feeBlock)
        }
    }

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

                if viewModel.confirmTransactionPolicy.needsHoldToConfirm {
                    bottomHoldAction
                } else {
                    bottomAction
                }
            }
            .readGeometry(\.frame.size, bindTo: $bottomViewSize)
        }
        .disableAnimations() // To force `.animation(nil)` behavior
    }

    private var bottomAction: some View {
        MainButton(
            title: viewModel.mainButtonState.title,
            icon: viewModel.mainButtonState.getIcon(tangemIconProvider: viewModel.tangemIconProvider),
            isLoading: viewModel.mainButtonIsLoading,
            isDisabled: !viewModel.mainButtonIsEnabled,
            action: viewModel.didTapMainButton
        )
    }

    private var bottomHoldAction: some View {
        HoldToConfirmButton(
            title: viewModel.mainButtonState.title,
            isLoading: viewModel.mainButtonIsLoading,
            isDisabled: !viewModel.mainButtonIsEnabled,
            action: viewModel.didTapMainButton
        )
    }

    @ViewBuilder
    private var legalView: some View {
        if let legalText = viewModel.legalText {
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

            Button(action: { isFocused = false }) {
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

            Button(action: { isFocused = false }) {
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
