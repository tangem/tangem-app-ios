//
//  FeeSelectorContentViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import SwiftUI
import TangemFoundation

class FeeSelectorContentViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var selectedFeeOption: FeeOption = .market
    @Published private(set) var feesRowData: [FeeSelectorContentRowViewModel] = []

    private let input: FeeSelectorContentViewModelInput
    private let output: FeeSelectorContentViewModelOutput
    private let analytics: FeeSelectorContentViewModelAnalytics
    private let customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder
    private let feeTokenItem: TokenItem

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: .init(),
        balanceConverter: .init()
    )

    init(
        input: FeeSelectorContentViewModelInput,
        output: FeeSelectorContentViewModelOutput,
        analytics: FeeSelectorContentViewModelAnalytics,
        customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder,
        feeTokenItem: TokenItem,
    ) {
        self.input = input
        self.output = output
        self.analytics = analytics
        self.customFieldsBuilder = customFieldsBuilder
        self.feeTokenItem = feeTokenItem

        bind(input: input)
    }

    func isSelected(_ option: FeeOption) -> BindingValue<Bool> {
        .init(root: self, default: false) { root in
            return root.selectedFeeOption == option
        } set: { root, isSelected in
            if isSelected {
                root.selectedFeeOption = option
                root.analytics.logSendFeeSelected(option)
            }
        }
    }

    func onAppear() {
        if let currentSelectedFee = input.selectedSelectorFee,
           currentSelectedFee.option != selectedFeeOption {
            selectedFeeOption = currentSelectedFee.option
        }
    }

    @MainActor
    func dismiss() {
        output.dismissFeeSelector()
    }

    @MainActor
    func done() {
        if let fee = input.selectorFees.first(where: { $0.option == selectedFeeOption }) {
            output.update(selectedSelectorFee: fee)
        }

        output.completeFeeSelection()
    }
}

// MARK: - Private

private extension FeeSelectorContentViewModel {
    func bind(input: FeeSelectorContentViewModelInput) {
        if let currentSelectedFee = input.selectedSelectorFee {
            selectedFeeOption = currentSelectedFee.option
        }

        input.selectorFeesPublisher
            // Skip a different loading states when fees is empty
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorContentRowViewModels(values: $1) }
            .receiveOnMain()
            .assign(to: &$feesRowData)
    }

    func mapToFeeSelectorContentRowViewModels(values: [FeeSelectorFee]) -> [FeeSelectorContentRowViewModel] {
        values
            .sorted(by: \.option)
            .map { mapToFeeRowViewModel(fee: $0) }
    }

    private func mapToFeeRowViewModel(fee: FeeSelectorFee) -> FeeSelectorContentRowViewModel {
        let feeComponents = feeFormatter.formattedFeeComponents(
            fee: fee.value,
            tokenItem: feeTokenItem,
            formattingOptions: .sendCryptoFeeFormattingOptions
        )

        // We will create the custom fields only for the `.custom` option
        let customFields = fee.option == .custom ? customFieldsBuilder.buildCustomFeeFields() : []

        return FeeSelectorContentRowViewModel(
            feeOption: fee.option,
            feeComponents: feeComponents,
            customFields: customFields
        )
    }
}
