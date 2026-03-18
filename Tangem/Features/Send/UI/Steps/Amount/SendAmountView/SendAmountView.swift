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

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: Constants.scrollViewSpacing)) {
            sourceSection
            destinationSection
        }
        .animation(viewModel.animateActiveFieldChange ? .easeInOut(duration: 0.45) : nil, value: viewModel.activeField)
        .animation(viewModel.animateDestinationRemoval ? .easeInOut(duration: 0.45) : nil, value: viewModel.destinationTokenViewType?.isAmountEditable ?? false)
        .onChange(of: viewModel.pendingFocusField) { field in
            guard let field else { return }
            viewModel.pendingFocusField = nil
            focusedField = focusTarget(for: field)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Source

    private var sourceSection: some View {
        let isAmountEditable = viewModel.destinationTokenViewType?.isAmountEditable ?? false
        let hasDestination = viewModel.destinationTokenViewType?.hasDestinationToken ?? false

        return SendAmountInputSectionView(
            isExpanded: isAmountEditable ? viewModel.activeField == .send : true,
            isLocked: isAmountEditable ? viewModel.isInputFieldSwitchingLocked : true,
            expandedTokenData: viewModel.sourceAmountTokenViewData,
            compactTokenData: isAmountEditable ? viewModel.compactSourceTokenViewData : nil,
            expandedContentVerticalPadding: viewModel.sourceRateBadge != nil ? 45 : 51,
            onTapCompact: { viewModel.userDidTapCompactField(.send) }
        ) {
            sourceHeaderWithInput
        }
        .overlay(alignment: .bottom) {
            if hasDestination {
                convertButton
                    .offset(y: convertButtonSize.height / 2 + Constants.scrollViewSpacing / 2)
            }
        }
        .zIndex(1)
    }

    private var sourceHeaderWithInput: some View {
        VStack(alignment: .center, spacing: 12) {
            if let header = viewModel.tokenHeader {
                SendTokenHeaderView(header: header)
                    .frame(minHeight: Constants.headerMinHeight)
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
            .accessibilityIdentifier(SendAccessibilityIdentifiers.convertToAnotherTokenButton)

        case .selected(let receivedTokenViewModel):
            GroupedSection(receivedTokenViewModel) {
                SendAmountTokenView(data: $0)
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.receiveTokenBlock)
            }
            .backgroundColor(Colors.Background.action)
            .innerContentPadding(0)

        case .selectedEditableAmount(let expandedDestinationData, _):
            SendAmountInputSectionView(
                isExpanded: viewModel.activeField == .receive,
                isLocked: viewModel.isInputFieldSwitchingLocked,
                expandedTokenData: expandedDestinationData,
                compactTokenData: viewModel.compactDestinationTokenViewData,
                expandedContentVerticalPadding: viewModel.destinationRateBadge != nil ? 45 : 51,
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
                .frame(minHeight: Constants.headerMinHeight)

            if let destinationField = viewModel.destinationAmountField {
                SendAmountInputView(
                    field: destinationField,
                    fiatIconURL: viewModel.fiatIconURL,
                    focusedField: $focusedField,
                    cryptoFocusValue: .destinationCrypto,
                    fiatFocusValue: .destinationFiat,
                    rateBadge: viewModel.destinationRateBadge,
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
            rateBadge: viewModel.sourceRateBadge,
            onWillToggle: {
                focusedField = viewModel.useFiatCalculation ? .sourceCrypto : .sourceFiat
            }
        )
    }

    private var convertButton: some View {
        CapsuleButton(icon: .trailing(Assets.clear), title: Localization.commonConvert, action: viewModel.removeReceivedToken)
            .accessibilityIdentifier(SendAccessibilityIdentifiers.removeConvertButton)
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
}

extension SendAmountView {
    enum Constants {
        static let scrollViewSpacing: CGFloat = 8
        /// Matches AccountIconView.Settings.smallSized total height (10pt icon + 4pt × 2 padding)
        static let headerMinHeight: CGFloat = 18
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
