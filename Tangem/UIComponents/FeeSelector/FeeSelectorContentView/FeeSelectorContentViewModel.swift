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

final class FeeSelectorContentViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published var selectedFeeOption: FeeOption = .market
    @Published private(set) var feesRowData: [FeeSelectorContentRowViewModel] = []
    @Published private(set) var doneButtonIsDisabled: Bool = false

    var showDoneButton: Bool {
        switch (savingType, selectedFeeOption) {
        case (.doneButton, _), (.autosave, .custom): true
        case (.autosave, _): false
        }
    }

    let dismissButtonType: FeeSelectorDismissButtonType

    private let input: FeeSelectorContentViewModelInput
    private let output: FeeSelectorContentViewModelOutput
    private let analytics: FeeSelectorContentViewModelAnalytics
    private let customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?
    private let feeTokenItem: TokenItem
    private let savingType: FeeSelectorSavingType

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: .init(),
        balanceConverter: .init()
    )

    init(
        input: FeeSelectorContentViewModelInput,
        output: FeeSelectorContentViewModelOutput,
        analytics: FeeSelectorContentViewModelAnalytics,
        customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?,
        feeTokenItem: TokenItem,
        dismissButtonType: FeeSelectorDismissButtonType = .close,
        savingType: FeeSelectorSavingType
    ) {
        self.input = input
        self.output = output
        self.analytics = analytics
        self.customFieldsBuilder = customFieldsBuilder
        self.feeTokenItem = feeTokenItem
        self.dismissButtonType = dismissButtonType
        self.savingType = savingType

        bind()
        bind(input: input)
    }

    func isSelected(_ option: FeeOption) -> BindingValue<Bool> {
        .init(root: self, default: false) { root in
            return root.selectedFeeOption == option
        } set: { root, isSelected in
            if isSelected {
                root.userDidSelect(option)
            }
        }
    }

    func onAppear() {
        analytics.logFeeStepOpened()
        customFieldsBuilder?.captureCustomFeeFieldsValue()

        if let currentSelectedFee = input.selectedSelectorFee,
           currentSelectedFee.option != selectedFeeOption {
            selectedFeeOption = currentSelectedFee.option
        }
    }

    func dismiss() {
        output.dismissFeeSelector()
        customFieldsBuilder?.resetCustomFeeFieldsValue()
    }

    func done() {
        updateFeeInOutput()
        output.completeFeeSelection()
    }
}

// MARK: - Private

private extension FeeSelectorContentViewModel {
    func userDidSelect(_ option: FeeOption) {
        selectedFeeOption = option
        analytics.logSendFeeSelected(option)

        guard savingType == .autosave, option != .custom else {
            return
        }

        done()
    }

    func updateFeeInOutput() {
        output.update(selectedFeeOption: selectedFeeOption)
    }

    func bind() {
        guard let customFieldsBuilder else {
            return
        }

        Publishers
            .CombineLatest($selectedFeeOption, customFieldsBuilder.customFeeIsValidPublisher)
            .map { option, isValid in
                switch option {
                case .custom: !isValid
                default: false
                }
            }
            .assign(to: &$doneButtonIsDisabled)
    }

    func bind(input: FeeSelectorContentViewModelInput) {
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

    func mapToFeeRowViewModel(fee: FeeSelectorFee) -> FeeSelectorContentRowViewModel {
        let feeComponents = feeFormatter.formattedFeeComponents(
            fee: fee.value,
            tokenItem: feeTokenItem,
            formattingOptions: .sendCryptoFeeFormattingOptions
        )

        // We will create the custom fields only for the `.custom` option
        let customFields = fee.option == .custom ? customFields() : []

        return FeeSelectorContentRowViewModel(
            feeOption: fee.option,
            feeComponents: feeComponents,
            customFields: customFields
        )
    }

    func customFields() -> [FeeSelectorCustomFeeRowViewModel] {
        customFieldsBuilder?.buildCustomFeeFields() ?? []
    }
}
