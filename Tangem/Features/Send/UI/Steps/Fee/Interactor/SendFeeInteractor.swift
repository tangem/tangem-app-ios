//
//  SendFeeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonSendFeeInteractor {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?

    private let provider: SendFeeProvider
    private let feeTokenItem: TokenItem
    private let customFeeProvider: FeeSelectorCustomFeeProvider?

    lazy var feeSelectorInteractor = CommonFeeSelectorInteractor(
        input: self,
        feeTokenItemsProvider: self,
        feesProvider: self,
        suggestedFeeProvider: nil,
        customFeeProvider: customFeeProvider
    )

    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        provider: SendFeeProvider,
        feeTokenItem: TokenItem,
        customFeeProvider: FeeSelectorCustomFeeProvider?
    ) {
        self.input = input
        self.output = output
        self.provider = provider
        self.feeTokenItem = feeTokenItem
        self.customFeeProvider = customFeeProvider

        bind()
    }

    func bind() {
        autoupdatedSuggestedFeeCancellable = feeSelectorInteractor
            .autoupdatedSuggestedFee
            .withWeakCaptureOf(self)
            .sink { $0.output?.feeDidChanged(fee: $1) }
    }
}

// MARK: - FeeSelectorInteractorInput

extension CommonSendFeeInteractor: FeeSelectorInteractorInput {
    var selectedFee: SendFee {
        input?.selectedFee ?? .init(option: .market, tokenItem: feeTokenItem, value: .loading)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedFeePublisher
    }
}

// MARK: - FeeSelectorFeesProvider

extension CommonSendFeeInteractor: FeeSelectorFeesProvider {
    var fees: [SendFee] {
        provider.fees
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        provider.feesPublisher.eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorFeeTokenItemsProvider

extension CommonSendFeeInteractor: FeeSelectorFeeTokenItemsProvider {
    var tokenItems: [TokenItem] {
        fees.map(\.tokenItem).unique()
    }

    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        feesPublisher.map { $0.map(\.tokenItem).unique() }.eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorOutput

extension CommonSendFeeInteractor: FeeSelectorOutput {
    func userDidSelect(selectedFee: SendFee) {
        output?.feeDidChanged(fee: selectedFee)
    }
}

// MARK: - FeeSelectorRoutable

extension CommonSendFeeInteractor: FeeSelectorRoutable {
    func dismissFeeSelector() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func completeFeeSelection() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
