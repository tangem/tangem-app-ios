//
//  SendAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemFoundation
import TangemAccessibilityIdentifiers
import struct TangemAccounts.AccountIconView

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel

    @FocusState private var focusedField: FocusedField?
    @State private var convertButtonSize: CGSize = .zero
    @State private var isCompactContentVisible: Bool = true

    private let scrollViewSpacing: CGFloat = 8

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: scrollViewSpacing)) {
            if case .accordion = viewModel.receivedTokenViewType {
                accordionContent
            } else {
                content
                receiveTokenView
            }
        }
        .animation(.easeInOut(duration: 0.45), value: viewModel.activeField)
        .onChange(of: viewModel.activeField) { activeField in
            isCompactContentVisible = false
            withAnimation(.easeInOut(duration: 0.25).delay(0.2)) {
                isCompactContentVisible = true
            }
            updateAccordionFocus(for: activeField)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    private var content: some View {
        VStack(alignment: .center, spacing: .zero) {
            VStack(alignment: .center, spacing: 12) {
                if let header = viewModel.tokenHeader {
                    SendTokenHeaderView(header: header)
                }

                sourceAmountInputView
            }
            .padding(.vertical, 45)

            Separator(color: Colors.Stroke.primary)

            if let sendAmountTokenViewData = viewModel.sendAmountTokenViewData {
                SendAmountTokenView(data: sendAmountTokenViewData)
            }
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
                    SendAmountTokenView(data: $0)
                }
                .backgroundColor(Colors.Background.action)
                .innerContentPadding(0)

                convertButton
            }

        case .accordion:
            EmptyView() // Handled by accordionContent
        }
    }

    // MARK: - Accordion

    @ViewBuilder
    private var accordionContent: some View {
        if case .accordion(let expandedData, let compactData, let textFieldVM) = viewModel.receivedTokenViewType {
            accordionSourceSection
                .overlay(alignment: .bottom) {
                    convertButton
                        .offset(y: convertButtonSize.height / 2 + scrollViewSpacing / 2)
                }
                .zIndex(1)

            accordionReceiveSection(
                expandedData: expandedData,
                compactData: compactData,
                textFieldVM: textFieldVM
            )
        }
    }

    private var accordionSourceSection: some View {
        let isExpanded = viewModel.activeField == .source
        let tokenData = isExpanded ? viewModel.sendAmountTokenViewData : viewModel.compactSourceTokenViewData

        return VStack(alignment: .center, spacing: .zero) {
            if isExpanded {
                VStack(alignment: .center, spacing: 12) {
                    if let header = viewModel.tokenHeader {
                        SendTokenHeaderView(header: header)
                    }

                    sourceAmountInputView
                }
                .padding(.vertical, 45)

                Separator(color: Colors.Stroke.primary)
            }

            if let tokenData {
                SendAmountTokenView(data: tokenData)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isExpanded else { return }
                        FeedbackGenerator.heavy()
                        viewModel.userDidTapCompactSource()
                    }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0)
    }

    private func accordionReceiveSection(
        expandedData: SendAmountTokenViewData,
        compactData: SendAmountTokenViewData,
        textFieldVM: DecimalNumberTextFieldViewModel
    ) -> some View {
        let isExpanded = viewModel.activeField == .receive
        let tokenData = isExpanded ? expandedData : compactData

        return VStack(alignment: .center, spacing: .zero) {
            if isExpanded {
                VStack(alignment: .center, spacing: 12) {
                    Text(Localization.sendWithSwapRecipientAmountTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    SendAmountInputView(
                        amountType: $viewModel.receiveAmountType,
                        cryptoTextFieldVM: textFieldVM,
                        cryptoOptions: viewModel.receiveTextFieldOptions,
                        fiatTextFieldVM: viewModel.receiveFiatTextFieldViewModel,
                        fiatOptions: viewModel.receiveFiatTextFieldOptions,
                        alternativeAmount: viewModel.receiveAlternativeAmount,
                        cryptoIconURL: viewModel.receiveCryptoIconURL,
                        fiatIconURL: viewModel.fiatIconURL,
                        possibleToConvertToFiat: viewModel.receivePossibleToConvertToFiat,
                        focusedField: $focusedField,
                        cryptoFocusValue: .receiveCrypto,
                        fiatFocusValue: .receiveFiat,
                        bottomInfoText: viewModel.receiveBottomInfoText,
                        onWillToggle: {
                            if focusedField != nil {
                                focusedField = viewModel.useReceiveFiatCalculation ? .receiveCrypto : .receiveFiat
                            }
                        }
                    )
                }
                .padding(.vertical, 45)

                Separator(color: Colors.Stroke.primary)
            }

            SendAmountTokenView(data: tokenData)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isExpanded else { return }
                    FeedbackGenerator.heavy()
                    viewModel.userDidTapCompactReceive()
                }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0)
    }

    private func updateAccordionFocus(for activeField: SendAmountViewModel.ActiveAmountField) {
        guard case .accordion = viewModel.receivedTokenViewType else { return }

        switch activeField {
        case .source:
            focusedField = viewModel.useFiatCalculation ? .sourceFiat : .sourceCrypto
        case .receive:
            focusedField = viewModel.useReceiveFiatCalculation ? .receiveFiat : .receiveCrypto
        }
    }

    private var convertButton: some View {
        CapsuleButton(icon: .trailing(Assets.clear), title: Localization.commonConvert, action: viewModel.removeReceivedToken)
            .readGeometry(\.frame.size, bindTo: $convertButtonSize)
    }

    private var sourceAmountInputView: some View {
        SendAmountInputView(
            amountType: $viewModel.amountType,
            cryptoTextFieldVM: viewModel.cryptoTextFieldViewModel,
            cryptoOptions: viewModel.cryptoTextFieldOptions,
            fiatTextFieldVM: viewModel.fiatTextFieldViewModel,
            fiatOptions: viewModel.fiatTextFieldOptions,
            alternativeAmount: viewModel.alternativeAmount,
            cryptoIconURL: viewModel.cryptoIconURL,
            fiatIconURL: viewModel.fiatIconURL,
            possibleToConvertToFiat: viewModel.possibleToConvertToFiat,
            focusedField: $focusedField,
            cryptoFocusValue: .sourceCrypto,
            fiatFocusValue: .sourceFiat,
            bottomInfoText: viewModel.bottomInfoText,
            accessibilityConfiguration: .source,
            onWillToggle: {
                focusedField = viewModel.useFiatCalculation ? .sourceCrypto : .sourceFiat
            }
        )
    }
}

extension SendAmountView {
    enum FocusedField: Hashable {
        case sourceCrypto
        case sourceFiat
        case receiveCrypto
        case receiveFiat
    }
}
