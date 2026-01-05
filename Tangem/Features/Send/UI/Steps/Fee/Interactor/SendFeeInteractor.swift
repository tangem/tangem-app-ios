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
    private let customFeeProvider: FeeSelectorCustomFeeProvider?

    lazy var feeSelectorInteractor = CommonFeeSelectorInteractor(
        input: self,
        feesProvider: self,
        suggestedFeeProvider: nil,
        customFeeProvider: customFeeProvider
    )

    private var autoupdatedSuggestedFeeCancellable: AnyCancellable?

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        provider: SendFeeProvider,
        customFeeProvider: FeeSelectorCustomFeeProvider?
    ) {
        self.input = input
        self.output = output
        self.provider = provider
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
        input?.selectedFee ?? .init(option: .market, value: .loading)
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

// MARK: - FeeSelectorContentViewModelOutput

extension CommonSendFeeInteractor: FeeSelectorContentViewModelOutput {
    func userDidSelect(selectedFee: FeeSelectorFee) {
        output?.feeDidChanged(fee: .init(option: selectedFee.option, value: selectedFee.value))
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

// MARK: - Private

private extension CommonSendFeeInteractor {
    func mapToSendFees(feesValue: LoadingResult<[SendFee], Error>) -> [SendFee] {
        switch feesValue {
        case .loading:
            return provider.feeOptions.map { SendFee(option: $0, value: .loading) }
        case .success(let fees):
            return fees.filter { provider.feeOptions.contains($0.option) }
        case .failure(let error):
            return provider.feeOptions.map { SendFee(option: $0, value: .failure(error)) }
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

        return SendFee(option: .custom, value: customFeeValue)
    }
}
