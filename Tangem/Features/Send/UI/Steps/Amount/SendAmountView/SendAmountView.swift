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
        if case .accordion(let expandedData, let compactData) = viewModel.receivedTokenViewType {
            SendAmountAccordionSectionView(
                isExpanded: viewModel.activeField == .source,
                expandedTokenData: viewModel.sendAmountTokenViewData,
                compactTokenData: viewModel.compactSourceTokenViewData,
                onTapCompact: viewModel.userDidTapCompactSource
            ) {
                VStack(alignment: .center, spacing: 12) {
                    if let header = viewModel.tokenHeader {
                        SendTokenHeaderView(header: header)
                    }

                    sourceAmountInputView
                }
            }
            .overlay(alignment: .bottom) {
                convertButton
                    .offset(y: convertButtonSize.height / 2 + scrollViewSpacing / 2)
            }
            .zIndex(1)

            SendAmountAccordionSectionView(
                isExpanded: viewModel.activeField == .receive,
                expandedTokenData: expandedData,
                compactTokenData: compactData,
                onTapCompact: viewModel.userDidTapCompactReceive
            ) {
                VStack(alignment: .center, spacing: 12) {
                    Text(Localization.sendWithSwapRecipientAmountTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    if let receiveField = viewModel.receiveAmountField {
                        SendAmountInputView(
                            field: receiveField,
                            fiatIconURL: viewModel.fiatIconURL,
                            focusedField: $focusedField,
                            cryptoFocusValue: .receiveCrypto,
                            fiatFocusValue: .receiveFiat,
                            onWillToggle: {
                                if focusedField != nil {
                                    focusedField = viewModel.useReceiveFiatCalculation ? .receiveCrypto : .receiveFiat
                                }
                            }
                        )
                    }
                }
            }
        }
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
            field: viewModel.sourceAmountField,
            fiatIconURL: viewModel.fiatIconURL,
            focusedField: $focusedField,
            cryptoFocusValue: .sourceCrypto,
            fiatFocusValue: .sourceFiat,
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
