//
//  FeeSelectorFeesViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemFoundation

protocol FeeSelectorFeesDataProvider {
    var selectedSelectorFee: LoadableTokenFee? { get }
    var selectedSelectorFeePublisher: AnyPublisher<LoadableTokenFee?, Never> { get }

    var selectorFees: [LoadableTokenFee] { get }
    var selectorFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> { get }
}

protocol FeeSelectorCustomFeeDataProviding {
    var customFeeProvider: (any CustomFeeProvider)? { get }
}

protocol FeeSelectorFeesRoutable: AnyObject {
    func userDidTapConfirmSelection(selectedFee: LoadableTokenFee)
}

final class FeeSelectorFeesViewModel: ObservableObject {
    @Published private(set) var rowViewModels: [FeeSelectorFeesRowViewModel] = []
    @Published private(set) var selectedFeeOption: FeeOption?

    @Published private(set) var customFeeManualSaveIsRequired: Bool
    @Published private(set) var customFeeManualSaveIsAvailable: Bool

    private let provider: FeeSelectorFeesDataProvider
    private let customFeeDataProvider: FeeSelectorCustomFeeDataProviding
    private let feeFormatter: FeeFormatter
    private let analytics: FeeSelectorAnalytics

    private weak var router: FeeSelectorFeesRoutable?

    private var selectedFee: LoadableTokenFee? {
        provider.selectorFees.first(where: { $0.option == selectedFeeOption })
    }

    init(
        provider: FeeSelectorFeesDataProvider,
        customFeeDataProvider: FeeSelectorCustomFeeDataProviding,
        feeFormatter: FeeFormatter,
        analytics: FeeSelectorAnalytics,
    ) {
        self.provider = provider
        self.customFeeDataProvider = customFeeDataProvider
        self.feeFormatter = feeFormatter
        self.analytics = analytics

        selectedFeeOption = provider.selectedSelectorFee?.option
        customFeeManualSaveIsRequired = provider.selectedSelectorFee?.option == .custom
        customFeeManualSaveIsAvailable = customFeeDataProvider.customFeeProvider?.customFeeIsValid == true

        rowViewModels = mapToFeeSelectorFeesRowViewModels(values: provider.selectorFees)

        bind()
    }

    func setup(router: FeeSelectorFeesRoutable) {
        self.router = router
    }

    func isSelected(_ fee: LoadableTokenFee) -> BindingValue<Bool> {
        .init(root: self, default: false) { root in
            root.selectedFeeOption == fee.option
        } set: { root, isSelected in
            if isSelected {
                root.userDidSelect(fee: fee)
            }
        }
    }

    func onAppear() {
        analytics.logFeeStepOpened()

        customFeeDataProvider.customFeeProvider?.captureCustomFeeFieldsValue()
        customFeeDataProvider.customFeeProvider?
            .customFeeIsValidPublisher
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsAvailable)

        if selectedFeeOption != provider.selectedSelectorFee?.option {
            selectedFeeOption = provider.selectedSelectorFee?.option
        }
    }

    func userDidRequestRevertCustomFeeValues() {
        customFeeDataProvider.customFeeProvider?.resetCustomFeeFieldsValue()
    }

    func userDidTapCustomFeeManualSaveButton() {
        guard let selectedFee else {
            assertionFailure("Selected fee should not be nil")
            return
        }

        router?.userDidTapConfirmSelection(selectedFee: selectedFee)
    }
}

// MARK: - Private

private extension FeeSelectorFeesViewModel {
    func bind() {
        provider.selectedSelectorFeePublisher
            .map { $0?.option }
            .receiveOnMain()
            .assign(to: &$selectedFeeOption)

        provider.selectorFeesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFeeSelectorFeesRowViewModels(values: $1) }
            .receiveOnMain()
            .assign(to: &$rowViewModels)

        $selectedFeeOption
            .map { $0 == .custom }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsRequired)
    }

    func userDidSelect(fee: LoadableTokenFee) {
        selectedFeeOption = fee.option
        analytics.logSendFeeSelected(fee.option)

        if fee.option != .custom {
            router?.userDidTapConfirmSelection(selectedFee: fee)
        }
    }
}

// MARK: - Mapping

private extension FeeSelectorFeesViewModel {
    func mapToFeeSelectorFeesRowViewModels(values: [LoadableTokenFee]) -> [FeeSelectorFeesRowViewModel] {
        values
            .sorted(by: \.option)
            .map { mapToFeeSelectorFeesRowViewModel(fee: $0) }
    }

    func mapToFeeSelectorFeesRowViewModel(fee: LoadableTokenFee) -> FeeSelectorFeesRowViewModel {
        let feeComponents = switch fee.value {
        // [REDACTED_TODO_COMMENT]
        case .loading, .failure:
            FormattedFeeComponents(cryptoFee: "-", fiatFee: .none)

        case .success(let feeValue): feeFormatter.formattedFeeComponents(
                fee: feeValue.amount.value,
                tokenItem: fee.tokenItem,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
        }

        // We will create the custom fields only for the `.custom` option
        let customFields = fee.option == .custom ? customFields() : []

        return FeeSelectorFeesRowViewModel(
            fee: fee,
            feeComponents: feeComponents,
            customFields: customFields
        )
    }

    func customFields() -> [FeeSelectorCustomFeeRowViewModel] {
        customFeeDataProvider.customFeeProvider?.buildCustomFeeFields() ?? []
    }
}
