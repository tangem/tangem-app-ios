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
    /// Matches AccountIconView.Settings.smallSized total height (10pt icon + 4pt × 2 padding)
    private let accordionHeaderMinHeight: CGFloat = 18

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: scrollViewSpacing)) {
            sourceSection
            receiveSection
        }
        .animation(viewModel.animateActiveFieldChange ? .easeInOut(duration: 0.45) : nil, value: viewModel.activeField)
        .animation(viewModel.animateAccordionExit ? .easeInOut(duration: 0.45) : nil, value: viewModel.receivedTokenViewType?.isAccordion ?? false)
        .onChange(of: viewModel.activeField) { activeField in
            // On first accordion entry animateActiveFieldChange is `false`.
            // Skip updateAccordionFocus — the delayed shouldFocusReceiveField
            // trigger will claim focus once the TextField is in the hierarchy.
            let isFirstAccordionEntry = !viewModel.animateActiveFieldChange
            viewModel.animateActiveFieldChange = true

            guard !isFirstAccordionEntry else { return }
            updateAccordionFocus(for: activeField)
        }
        .onChange(of: viewModel.shouldFocusSendField) { shouldFocus in
            guard shouldFocus else { return }
            viewModel.shouldFocusSendField = false
            focusedField = viewModel.useFiatCalculation ? .sourceFiat : .sourceCrypto
        }
        .onChange(of: viewModel.shouldFocusReceiveField) { shouldFocus in
            guard shouldFocus else { return }
            viewModel.shouldFocusReceiveField = false
            focusedField = viewModel.useReceiveFiatCalculation ? .receiveFiat : .receiveCrypto
        }
        .onChange(of: focusedField) { newValue in
            print("🔴 [SendAmountView] focusedField changed to: \(String(describing: newValue))")
        }
        .onChange(of: viewModel.receivedTokenViewType?.isAccordion ?? false) { _ in
            viewModel.animateAccordionExit = false
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Source

    private var sourceSection: some View {
        let isAccordion = viewModel.receivedTokenViewType?.isAccordion ?? false

        return SendAmountAccordionSectionView(
            isExpanded: isAccordion ? viewModel.activeField == .send : true,
            isLocked: isAccordion ? viewModel.isAccordionSwitchingLocked : true,
            expandedTokenData: viewModel.sendAmountTokenViewData,
            compactTokenData: isAccordion ? viewModel.compactSendTokenViewData : nil,
            onTapCompact: viewModel.userDidTapCompactSource
        ) {
            sourceHeaderWithInput
        }
        .overlay(alignment: .bottom) {
            if isAccordion {
                convertButton
                    .offset(y: convertButtonSize.height / 2 + scrollViewSpacing / 2)
            }
        }
        .zIndex(isAccordion ? 1 : 0)
    }

    private var sourceHeaderWithInput: some View {
        VStack(alignment: .center, spacing: 12) {
            if let header = viewModel.tokenHeader {
                SendTokenHeaderView(header: header)
                    .frame(minHeight: accordionHeaderMinHeight)
            }

            sourceAmountInputView
        }
    }

    // MARK: - Receive

    @ViewBuilder
    private var receiveSection: some View {
        switch viewModel.receivedTokenViewType {
        case .none:
            EmptyView()

        case .selectButton:
            Button {
                focusedField = nil
                viewModel.userDidTapReceivedTokenSelection()
            } label: {
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
                    .offset(y: -(convertButtonSize.height + scrollViewSpacing) / 2)
            }

        case .accordion(let expandedReceiveData, _):
            SendAmountAccordionSectionView(
                isExpanded: viewModel.activeField == .receive,
                isLocked: viewModel.isAccordionSwitchingLocked,
                expandedTokenData: expandedReceiveData,
                compactTokenData: viewModel.compactReceiveTokenViewData,
                onTapCompact: viewModel.userDidTapCompactReceive
            ) {
                receiveHeaderWithInput
            }
        }
    }

    private var receiveHeaderWithInput: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(Localization.sendWithSwapRecipientAmountTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .frame(minHeight: accordionHeaderMinHeight)

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

    // MARK: - Helpers

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

    private var convertButton: some View {
        CapsuleButton(icon: .trailing(Assets.clear), title: Localization.commonConvert, action: viewModel.removeReceivedToken)
            .readGeometry(\.frame.size, bindTo: $convertButtonSize)
    }

    private func updateAccordionFocus(for activeField: ActiveAmountField) {
        guard viewModel.receivedTokenViewType?.isAccordion == true else { return }

        switch activeField {
        case .send:
            focusedField = viewModel.useFiatCalculation ? .sourceFiat : .sourceCrypto
        case .receive:
            focusedField = viewModel.useReceiveFiatCalculation ? .receiveFiat : .receiveCrypto
        }
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
