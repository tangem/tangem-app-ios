//
//  WCFeeSelectorContentViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import SwiftUI
import TangemFoundation

final class WCFeeSelectorContentViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published var selectedFeeOption: FeeOption = .market
    @Published private(set) var feesRowData: [WCFeeSelectorContentRowViewModel] = []
    @Published private(set) var doneButtonIsDisabled: Bool = false

    var showDoneButton: Bool {
        switch (savingType, selectedFeeOption) {
        case (.doneButton, _), (.autosave, .custom): true
        case (.autosave, _): false
        }
    }

    let dismissButtonType: FeeSelectorDismissButtonType

    private let input: WCFeeSelectorContentViewModelInput
    private let output: WCFeeSelectorContentViewModelOutput
    private let analytics: FeeSelectorContentViewModelAnalytics
    private let customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?
    private let customAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?
    private let feeTokenItem: TokenItem
    private let savingType: FeeSelectorSavingType

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: .init(),
        balanceConverter: .init()
    )

    init(
        input: WCFeeSelectorContentViewModelInput,
        output: WCFeeSelectorContentViewModelOutput,
        analytics: FeeSelectorContentViewModelAnalytics,
        customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?,
        customAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?,
        feeTokenItem: TokenItem,
        dismissButtonType: FeeSelectorDismissButtonType = .close,
        savingType: FeeSelectorSavingType
    ) {
        self.input = input
        self.output = output
        self.analytics = analytics
        self.customFieldsBuilder = customFieldsBuilder
        self.customAvailabilityProvider = customAvailabilityProvider
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
        customAvailabilityProvider?.captureCustomFeeFieldsValue()

        if let currentSelectedFee = input.selectedSelectorFee,
           currentSelectedFee.option != selectedFeeOption {
            selectedFeeOption = currentSelectedFee.option
        }
    }

    func dismiss() {
        output.dismissFeeSelector()
        customAvailabilityProvider?.resetCustomFeeFieldsValue()
    }

    func done() {
        updateFeeInOutput()
        output.completeFeeSelection()
    }
}

// MARK: - Private

private extension WCFeeSelectorContentViewModel {
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
        guard let customAvailabilityProvider else {
            return
        }

        Publishers
            .CombineLatest($selectedFeeOption, customAvailabilityProvider.customFeeIsValidPublisher)
            .map { option, isValid in
                switch option {
                case .custom: !isValid
                default: false
                }
            }
            .assign(to: &$doneButtonIsDisabled)
    }

    func bind(input: WCFeeSelectorContentViewModelInput) {
        input.selectorFeesPublisher
            // Skip a different loading states when fees is empty
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorContentRowViewModels(values: $1) }
            .receiveOnMain()
            .assign(to: &$feesRowData)
    }

    func mapToFeeSelectorContentRowViewModels(values: [WCFeeSelectorFee]) -> [WCFeeSelectorContentRowViewModel] {
        values
            .sorted(by: \.option)
            .map { mapToFeeRowViewModel(fee: $0) }
    }

    func mapToFeeRowViewModel(fee: WCFeeSelectorFee) -> WCFeeSelectorContentRowViewModel {
        let feeComponents = feeFormatter.formattedFeeComponents(
            fee: fee.value,
            tokenItem: feeTokenItem,
            formattingOptions: .sendCryptoFeeFormattingOptions
        )

        // We will create the custom fields only for the `.custom` option
        let customFields = fee.option == .custom ? customFields() : []

        return WCFeeSelectorContentRowViewModel(
            feeOption: fee.option,
            feeComponents: feeComponents,
            customFields: customFields
        )
    }

    func customFields() -> [FeeSelectorCustomFeeRowViewModel] {
        customFieldsBuilder?.buildCustomFeeFields() ?? []
    }
}
