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

    private var feesSubscriptions: AnyCancellable?

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
                root.analytics.didSelectFeeOption(option)
            }
        }
    }

    @MainActor
    func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }

    @MainActor
    func done() {
        if let fee = input.selectorFees.first(where: { $0.option == selectedFeeOption }) {
            output.update(selectedSelectorFee: fee)
        }

        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Private

private extension FeeSelectorContentViewModel {
    func bind(input: FeeSelectorContentViewModelInput) {
        feesSubscriptions = input.selectorFeesPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, values in
                viewModel.updateViewModels(values: values)
            }
    }

    func updateViewModels(values: [FeeSelectorFee]) {
        feesRowData = values.compactMap { fee in
            mapToFeeRowViewModel(fee: fee)
        }
    }

    private func mapToFeeRowViewModel(fee: FeeSelectorFee) -> FeeSelectorContentRowViewModel? {
        // Temporary turn off the `.custom` fee
        // [REDACTED_TODO_COMMENT]
        guard fee.option != .custom else {
            return nil
        }

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
