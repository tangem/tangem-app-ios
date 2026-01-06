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
    var selectedSelectorFee: FeeSelectorFee { get }
    var selectedSelectorFeePublisher: AnyPublisher<FeeSelectorFee, Never> { get }

    var selectorFees: [FeeSelectorFee] { get }
    var selectorFeesPublisher: AnyPublisher<[FeeSelectorFee], Never> { get }
}

protocol FeeSelectorFeesRoutable: AnyObject {
    func userDidTapConfirmSelection(selectedFee: FeeSelectorFee)
}

final class FeeSelectorFeesViewModel: ObservableObject {
    @Published private(set) var rowViewModels: [FeeSelectorFeesRowViewModel]
    @Published private(set) var selectedFee: FeeSelectorFee

    @Published private(set) var customFeeManualSaveIsRequired: Bool
    @Published private(set) var customFeeManualSaveIsAvailable: Bool

    private let provider: FeeSelectorFeesDataProvider
    private let mapper: FeeSelectorFeesViewModelMapper
    private let customFeeAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?
    private let analytics: FeeSelectorAnalytics

    private weak var router: FeeSelectorFeesRoutable?

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

        selectedFee = provider.selectedSelectorFee
        rowViewModels = mapper.mapToFeeSelectorFeesRowViewModels(values: provider.selectorFees)

        customFeeManualSaveIsRequired = provider.selectedSelectorFee.option == .custom
        customFeeManualSaveIsAvailable = customFeeAvailabilityProvider?.customFeeIsValid == true

        bind()
    }

    func setup(router: FeeSelectorFeesRoutable) {
        self.router = router
    }

    func isSelected(_ fee: FeeSelectorFee) -> BindingValue<Bool> {
        .init(root: self, default: false) { root in
            root.selectedFee.option == fee.option
        } set: { root, isSelected in
            if isSelected {
                root.userDidSelect(fee: fee)
            }
        }
    }

    func onAppear() {
        analytics.logFeeStepOpened()
        customFeeAvailabilityProvider?.captureCustomFeeFieldsValue()

        if selectedFee.option != provider.selectedSelectorFee.option {
            selectedFee = provider.selectedSelectorFee
        }
    }

    func userDidRequestRevertCustomFeeValues() {
        customFeeAvailabilityProvider?.resetCustomFeeFieldsValue()
    }

    func userDidTapCustomFeeManualSaveButton() {
        router?.userDidTapConfirmSelection(selectedFee: selectedFee)
    }
}

// MARK: - Private

private extension FeeSelectorFeesViewModel {
    func bind() {
        provider.selectedSelectorFeePublisher
            .receiveOnMain()
            .assign(to: &$selectedFee)

        provider.selectorFeesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapper.mapToFeeSelectorFeesRowViewModels(values: $1) }
            .receiveOnMain()
            .assign(to: &$rowViewModels)

        $selectedFee
            .map { $0.option == .custom }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsRequired)

        customFeeAvailabilityProvider?
            .customFeeIsValidPublisher
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsAvailable)
    }

    func userDidSelect(fee: FeeSelectorFee) {
        selectedFee = fee
        analytics.logSendFeeSelected(fee.option)

        if fee.option != .custom {
            router?.userDidTapConfirmSelection(selectedFee: selectedFee)
        }
    }
}
