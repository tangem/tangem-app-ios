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
    private let customFeeService: CustomFeeService?
    private let _customFee: CurrentValueSubject<BSDKFee?, Never> = .init(.none)

    lazy var feeSelectorInteractor = CommonFeeSelectorInteractor(
        input: self,
        feesProvider: self,
        suggestedFeeProvider: nil,
        customFeeProvider: customFeeService == nil ? nil : self
    )

    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        provider: SendFeeProvider,
        feeTokenItem: TokenItem,
        customFeeService: CustomFeeService?
    ) {
        self.input = input
        self.output = output
        self.provider = provider
        self.feeTokenItem = feeTokenItem
        self.customFeeService = customFeeService

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
        mapToSendFees(feesValue: provider.fees)
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        provider.feesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToSendFees(feesValue: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorFeesProvider

extension CommonSendFeeInteractor: FeeSelectorCustomFeeProvider {
    var customFee: SendFee {
        mapToCustomFee(customFee: _customFee.value)
    }

    var customFeePublisher: AnyPublisher<SendFee, Never> {
        _customFee
            .withWeakCaptureOf(self)
            .map { $0.mapToCustomFee(customFee: $1) }
            .eraseToAnyPublisher()
    }

    func initialSetupCustomFee(_ fee: BSDKFee) {
        _customFee.send(fee)
        customFeeService?.initialSetupCustomFee(fee)
    }
}

// MARK: - FeeSelectorContentViewModelOutput

extension CommonSendFeeInteractor: FeeSelectorContentViewModelOutput {
    func userDidSelect(selectedFee: FeeSelectorFee) {
        output?.feeDidChanged(fee: .init(option: selectedFee.option, tokenItem: selectedFee.tokenItem, value: selectedFee.value))
    }
}

// MARK: - FeeSelectorContentViewModelRoutable

extension CommonSendFeeInteractor: FeeSelectorContentViewModelRoutable {
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

// MARK: - CustomFeeServiceOutput

extension CommonSendFeeInteractor: CustomFeeServiceOutput {
    func customFeeDidChanged(_ customFee: BSDKFee) {
        _customFee.send(customFee)
    }
}

// MARK: - Private

private extension CommonSendFeeInteractor {
    func mapToSendFees(feesValue: LoadingResult<[SendFee], Error>) -> [SendFee] {
        switch feesValue {
        case .loading:
            return provider.feeOptions.map { SendFee(option: $0, tokenItem: feeTokenItem, value: .loading) }
        case .success(let fees):
            return fees.filter { provider.feeOptions.contains($0.option) }
        case .failure(let error):
            return provider.feeOptions.map { SendFee(option: $0, tokenItem: feeTokenItem, value: .failure(error)) }
        }
    }

    func mapToCustomFee(customFee: BSDKFee?) -> SendFee {
        let customFeeValue: LoadingResult<BSDKFee, any Error> = {
            if let customFee {
                return .success(customFee)
            }

            if let marketFee = fees.first(where: { $0.option == .market })?.value {
                return marketFee
            }

            assertionFailure("Market fee is not found. Return endless .loading state")
            return .loading
        }()

        return SendFee(
            option: .custom,
            tokenItem: feeTokenItem,
            value: customFeeValue,
        )
    }
}
