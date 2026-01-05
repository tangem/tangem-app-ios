//
//  FeeSelectorContentViewModel.swift
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

final class FeeSelectorContentViewModel: ObservableObject, FloatingSheetContentViewModel {
    // [REDACTED_TODO_COMMENT]
    // [REDACTED_USERNAME] private(set) var feesTokenItems: [FeeSelectorContentRowViewModel] = []

    @Published private(set) var rowViewModels: [FeeSelectorContentRowViewModel]

    @Published private(set) var selectedFee: FeeSelectorFee

    @Published private(set) var customFeeManualSaveIsRequired: Bool
    @Published private(set) var customFeeManualSaveIsAvailable: Bool

    private let provider: FeeSelectorFeesDataProvider
    private let output: FeeSelectorContentViewModelOutput

    private let mapper: FeeSelectorContentViewModelMapper
    private let customFeeAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?
    private let analytics: FeeSelectorContentViewModelAnalytics

    private weak var router: FeeSelectorContentViewModelRoutable?

    init(
        provider: FeeSelectorFeesDataProvider,
        output: FeeSelectorContentViewModelOutput,
        mapper: FeeSelectorContentViewModelMapper,
        customFeeAvailabilityProvider: FeeSelectorCustomFeeAvailabilityProvider?,
        analytics: FeeSelectorContentViewModelAnalytics,
        router: FeeSelectorContentViewModelRoutable
    ) {
        self.provider = provider
        self.output = output
        self.mapper = mapper
        self.customFeeAvailabilityProvider = customFeeAvailabilityProvider
        self.analytics = analytics
        self.router = router

        selectedFee = provider.selectedSelectorFee
        rowViewModels = mapper.mapToFeeSelectorContentRowViewModels(values: provider.selectorFees)

        customFeeManualSaveIsRequired = provider.selectedSelectorFee.option == .custom
        customFeeManualSaveIsAvailable = customFeeAvailabilityProvider?.customFeeIsValid == true

        bind()
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

    func userDidTapDismissButton() {
        router?.dismissFeeSelector()
        customFeeAvailabilityProvider?.resetCustomFeeFieldsValue()
    }

    func userDidTapCustomFeeManualSaveButton() {
        done()
    }
}

// MARK: - Private

private extension FeeSelectorContentViewModel {
    func bind() {
        provider.selectedSelectorFeePublisher
            .receiveOnMain()
            .assign(to: &$selectedFee)

        provider.selectorFeesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapper.mapToFeeSelectorContentRowViewModels(values: $1) }
            .receiveOnMain()
            .assign(to: &$rowViewModels)

        $selectedFee
            .map { $0.option == .custom }
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsRequired)

        customFeeAvailabilityProvider?
            .customFeeIsValidPublisher
            .receiveOnMain()
            .assign(to: &$customFeeManualSaveIsAvailable)
    }

    func userDidSelect(fee: FeeSelectorFee) {
        selectedFee = fee
        analytics.logSendFeeSelected(fee.option)

        if fee.option != .custom {
            done()
        }
    }

    func done() {
        output.userDidSelect(selectedFee: selectedFee)
        router?.completeFeeSelection()
    }
}
