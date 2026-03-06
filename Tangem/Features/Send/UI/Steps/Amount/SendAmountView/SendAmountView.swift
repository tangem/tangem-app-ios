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
            destinationSection
        }
        .animation(viewModel.animateActiveFieldChange ? .easeInOut(duration: 0.45) : nil, value: viewModel.activeField)
        .animation(viewModel.animateAccordionExit ? .easeInOut(duration: 0.45) : nil, value: viewModel.destinationTokenViewType?.isAccordion ?? false)
        .onChange(of: viewModel.activeField) { activeField in
            // On first accordion entry animateActiveFieldChange is `false`.
            // Skip updateAccordionFocus — the delayed pendingFocusField
            // trigger will claim focus once the TextField is in the hierarchy.
            let isFirstAccordionEntry = !viewModel.animateActiveFieldChange
            viewModel.animateActiveFieldChange = true

            guard !isFirstAccordionEntry else { return }
            updateAccordionFocus(for: activeField)
        }
        .onChange(of: viewModel.pendingFocusField) { field in
            guard let field else { return }
            viewModel.pendingFocusField = nil
            focusedField = focusTarget(for: field)
        }
        .onChange(of: viewModel.destinationTokenViewType?.isAccordion ?? false) { _ in
            viewModel.animateAccordionExit = false
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Source

    private var sourceSection: some View {
        let isAccordion = viewModel.destinationTokenViewType?.isAccordion ?? false

        return SendAmountAccordionSectionView(
            isExpanded: isAccordion ? viewModel.activeField == .send : true,
            isLocked: isAccordion ? viewModel.isAccordionSwitchingLocked : true,
            expandedTokenData: viewModel.sourceAmountTokenViewData,
            compactTokenData: isAccordion ? viewModel.compactSourceTokenViewData : nil,
            onTapCompact: { viewModel.userDidTapCompactField(.send) }
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
    private var destinationSection: some View {
        switch viewModel.destinationTokenViewType {
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

        case .accordion(let expandedDestinationData, _):
            SendAmountAccordionSectionView(
                isExpanded: viewModel.activeField == .receive,
                isLocked: viewModel.isAccordionSwitchingLocked,
                expandedTokenData: expandedDestinationData,
                compactTokenData: viewModel.compactDestinationTokenViewData,
                onTapCompact: { viewModel.userDidTapCompactField(.receive) }
            ) {
                destinationHeaderWithInput
            }
        }
    }

    private var destinationHeaderWithInput: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(Localization.sendWithSwapRecipientAmountTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .frame(minHeight: accordionHeaderMinHeight)

            if let destinationField = viewModel.destinationAmountField {
                SendAmountInputView(
                    field: destinationField,
                    fiatIconURL: viewModel.fiatIconURL,
                    focusedField: $focusedField,
                    cryptoFocusValue: .destinationCrypto,
                    fiatFocusValue: .destinationFiat,
                    onWillToggle: {
                        if focusedField != nil {
                            focusedField = viewModel.useDestinationFiatCalculation ? .destinationCrypto : .destinationFiat
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

    private func focusTarget(for field: ActiveAmountField) -> FocusedField {
        switch field {
        case .send:
            return viewModel.useFiatCalculation ? .sourceFiat : .sourceCrypto
        case .receive:
            return viewModel.useDestinationFiatCalculation ? .destinationFiat : .destinationCrypto
        }
    }

    private func updateAccordionFocus(for activeField: ActiveAmountField) {
        guard viewModel.destinationTokenViewType?.isAccordion == true else { return }
        focusedField = focusTarget(for: activeField)
    }
}

extension SendAmountView {
    enum FocusedField: Hashable {
        case sourceCrypto
        case sourceFiat
        case destinationCrypto
        case destinationFiat
    }
}
