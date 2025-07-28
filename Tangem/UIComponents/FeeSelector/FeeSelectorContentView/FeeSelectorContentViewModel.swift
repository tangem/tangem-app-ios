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
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published var selectedFeeOption: FeeOption = .market
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

    private var bag: Set<AnyCancellable> = []

    init(
        input: FeeSelectorContentViewModelInput,
        output: FeeSelectorContentViewModelOutput,
        analytics: FeeSelectorContentViewModelAnalytics,
        customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder,
        feeTokenItem: TokenItem
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
            root.selectedFeeOption == option
        } set: { root, isSelected in
            root.selectedFeeOption = option

            if isSelected {
                root.analytics.logSendFeeSelected(option)
            }
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
            .receiveOnMain()
            .sink { viewModel, values in
                viewModel.updateViewModels(values: values)
            }
            .store(in: &bag)

        input.selectedSelectorFeePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, selectedFee in
                viewModel.selectedFeeOption = selectedFee.option
            }
            .store(in: &bag)
    }

    func updateViewModels(values: [FeeSelectorFee]) {
        feesRowData = values.compactMap { fee in
            mapToFeeRowViewModel(fee: fee)
        }
    }

    private func mapToFeeRowViewModel(fee: FeeSelectorFee) -> FeeSelectorContentRowViewModel? {
        let feeComponents = feeFormatter.formattedFeeComponents(
            fee: fee.value,
            tokenItem: feeTokenItem,
            formattingOptions: .sendCryptoFeeFormattingOptions
        )

        return FeeSelectorContentRowViewModel(
            feeOption: fee.option,
            feeComponents: feeComponents,
            customFields: customFieldsBuilder.buildCustomFeeFields()
        )
    }
}
