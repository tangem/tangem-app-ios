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
    var selectedSelectorFee: TokenFee? { get }
    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> { get }

    var selectorFees: [TokenFee] { get }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> { get }
}

protocol FeeSelectorFeesRoutable: AnyObject {
    func userDidTapConfirmSelection(selectedFee: TokenFee)
}

final class FeeSelectorFeesViewModel: ObservableObject {
    @Published private(set) var rowViewModels: [FeeSelectorFeesRowViewModel]
    @Published private(set) var selectedFeeOption: FeeOption?

    @Published private(set) var customFeeManualSaveIsRequired: Bool
    @Published private(set) var customFeeManualSaveIsAvailable: Bool

    private let provider: FeeSelectorFeesDataProvider
    private let mapper: FeeSelectorFeesViewModelMapper
    private let customFeeAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?
    private let analytics: FeeSelectorAnalytics

    private weak var router: FeeSelectorFeesRoutable?

    private var selectedFee: TokenFee? {
        provider.selectorFees.first(where: { $0.option == selectedFeeOption })
    }

    init(
        provider: FeeSelectorFeesDataProvider,
        mapper: FeeSelectorFeesViewModelMapper,
        customFeeAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?,
        analytics: FeeSelectorAnalytics,
    ) {
        self.provider = provider
        self.mapper = mapper
        self.customFeeAvailabilityProvider = customFeeAvailabilityProvider
        self.analytics = analytics

        selectedFeeOption = provider.selectedSelectorFee?.option
        rowViewModels = mapper.mapToFeeSelectorFeesRowViewModels(values: provider.selectorFees)

        customFeeManualSaveIsRequired = provider.selectedSelectorFee?.option == .custom
        customFeeManualSaveIsAvailable = customFeeAvailabilityProvider?.customFeeIsValid == true

        bind()
    }

    func setup(router: FeeSelectorFeesRoutable) {
        self.router = router
    }

    func isSelected(_ fee: TokenFee) -> BindingValue<Bool> {
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
        customFeeAvailabilityProvider?.captureCustomFeeFieldsValue()

        if selectedFeeOption != provider.selectedSelectorFee?.option {
            selectedFeeOption = provider.selectedSelectorFee?.option
        }
    }

    func userDidRequestRevertCustomFeeValues() {
        customFeeAvailabilityProvider?.resetCustomFeeFieldsValue()
    }

    func userDidTapCustomFeeManualSaveButton() {
        guard let selectedFee else { return }

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
            .map { $0.mapper.mapToFeeSelectorFeesRowViewModels(values: $1) }
            .receiveOnMain()
            .assign(to: &$rowViewModels)

        $selectedFeeOption
            .map { $0 == .custom }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsRequired)

        customFeeAvailabilityProvider?
            .customFeeIsValidPublisher
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsAvailable)
    }

    func userDidSelect(fee: TokenFee) {
        selectedFeeOption = fee.option
        analytics.logSendFeeSelected(fee.option)

        if fee.option != .custom {
            router?.userDidTapConfirmSelection(selectedFee: fee)
        }
    }
}
