//
//  SendNewAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendNewAmountView: View {
    @ObservedObject var viewModel: SendNewAmountViewModel
    let transitionService: SendTransitionService

    @FocusState private var focused: SendAmountCalculationType?
    @State private var convertButtonSize: CGSize = .zero

    private let scrollViewSpacing: CGFloat = 8

    var body: some View {
        GroupedScrollView(spacing: scrollViewSpacing) {
            content
            receiveTokenView
        }
        .transition(transitionService.transitionToNewAmountStep())
        .onAppear(perform: viewModel.onAppear)
    }

    private var content: some View {
        VStack(alignment: .center, spacing: .zero) {
            VStack(alignment: .center, spacing: 12) {
                Text(.init(Localization.sendFromWallet(viewModel.walletHeaderText)))
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                VStack(alignment: .center, spacing: .zero) {
                    textField

                    bottomInfoText
                }
            }
            .padding(.vertical, 45)
            .ignoresSafeArea()

            Separator(color: Colors.Stroke.primary)

            SendNewAmountTokenView(data: viewModel.tokenWithAmountViewData)
                .padding(.vertical, 14)
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0)
    }

    @ViewBuilder
    private var receiveTokenView: some View {
        switch viewModel.receivedTokenViewType {
        case .none:
            EmptyView()

        case .selectButton:
            Button(action: viewModel.userDidTapReceivedTokenSelection) {
                HStack(spacing: 8) {
                    Assets.Glyphs.convertMiniNew.image
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Colors.Text.tertiary)
                        .padding(.all, 3)
                        .background(Circle().fill(Colors.Icon.secondary.opacity(0.1)))

                    Text(Localization.sendAmountConvertToAnotherToken)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                }
                .padding(.vertical, 13)
                .infinityFrame()
            }

        case .selected(let receivedTokenViewModel):
            ZStack(alignment: .top) {
                GroupedSection(receivedTokenViewModel) {
                    SendNewAmountTokenView(data: $0)
                }
                .backgroundColor(Colors.Background.action)
                .innerContentPadding(14)

                CircleButton(
                    content: .title(icon: .trailing(Assets.clear), title: Localization.commonConvert),
                    action: viewModel.removeReceivedToken
                )
                .readGeometry(\.frame.size, bindTo: $convertButtonSize)
                .offset(y: -(convertButtonSize.height + scrollViewSpacing) / 2)
            }
        }
    }

    @ViewBuilder
    private var textField: some View {
        switch viewModel.amountType {
        case .crypto:
            SendDecimalNumberTextField(viewModel: viewModel.cryptoTextFieldViewModel)
                .prefixSuffixOptions(viewModel.cryptoTextFieldOptions)
                .alignment(.center)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .appearance(.init(font: Fonts.Regular.largeTitle.weight(.semibold)))
                .focused($focused, equals: .crypto)
                .frame(height: 42)
                .transition(
                    .asymmetric(
                        insertion: Constants.textFieldTransition.animation(Constants.animation.delay(Constants.duration)),
                        removal: Constants.textFieldTransition.animation(Constants.animation)
                    )
                )
        case .fiat:
            SendDecimalNumberTextField(viewModel: viewModel.fiatTextFieldViewModel)
                .prefixSuffixOptions(viewModel.fiatTextFieldOptions)
                .alignment(.center)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .appearance(.init(font: Fonts.Regular.largeTitle.weight(.semibold)))
                .focused($focused, equals: .fiat)
                .frame(height: 42)
                .transition(
                    .asymmetric(
                        insertion: Constants.textFieldTransition.animation(Constants.animation.delay(Constants.duration)),
                        removal: Constants.textFieldTransition.animation(Constants.animation)
                    )
                )
        }
    }

    private var bottomInfoText: some View {
        Group {
            switch viewModel.bottomInfoText {
            case .none where viewModel.possibleToChangeAmountType:
                Button(action: {
                    // If keyboard was activated
                    // Update `focused` before change text filed to avoid the keyboard jumping
                    if focused != nil {
                        focused = viewModel.useFiatCalculation ? .crypto : .fiat
                    }

                    viewModel.useFiatCalculation.toggle()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    alternativeView
                }
            case .info(let string):
                Text(string)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.attention)
                    .padding(.vertical, 8)
            case .error(let string):
                Text(string)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.warning)
                    .padding(.vertical, 8)
            case .none:
                Text(" ") // Hold empty space
                    .style(Fonts.Regular.subheadline, color: Colors.Text.warning)
                    .padding(.vertical, 8)
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }

    private var alternativeView: some View {
        HStack(spacing: 8) {
            Assets.Glyphs.exchange.image
                .rotation3DEffect(.degrees(viewModel.useFiatCalculation ? 180 : .zero), axis: (1, 0, 0))
                .animation(Constants.animation, value: viewModel.useFiatCalculation)
                .zIndex(1)

            HStack(spacing: 4) {
                Text(viewModel.alternativeAmount)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                    .lineLimit(1)

                IconView(
                    url: viewModel.useFiatCalculation ? viewModel.cryptoIconURL : viewModel.fiatIconURL,
                    size: CGSize(width: 14, height: 14)
                )
            }
            .id(viewModel.useFiatCalculation)
            .animation(.none, value: viewModel.alternativeAmount)
            .transition(
                .asymmetric(
                    insertion: Constants.alternativeAmountTransition.animation(Constants.animation.delay(Constants.duration)),
                    removal: Constants.alternativeAmountTransition.animation(Constants.animation)
                )
            )
        }
        .animation(Constants.animation, value: viewModel.alternativeAmount)
        // Expand tappable area
        .padding(.all, 8)
    }
}

extension SendNewAmountView {
    enum Constants {
        static let duration: TimeInterval = 0.2
        static let animation: Animation = .linear(duration: duration)
        static let textFieldTransition: AnyTransition = .opacity.combined(with: .scale(scale: duration, anchor: .bottom))
        static let alternativeAmountTransition: AnyTransition = .opacity
    }
}
