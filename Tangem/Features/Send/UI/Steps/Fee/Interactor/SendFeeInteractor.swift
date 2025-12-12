//
//  SendFeeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol SendFeeInteractor {
    var selectedFee: SendFee? { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }
    var feesPublisher: AnyPublisher<[SendFee], Never> { get }

    func update(selectedFee: SendFee)
}

final class CommonSendFeeInteractor {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?

    private let provider: SendFeeProvider
    private let customFeeService: CustomFeeService?
    private let _customFee: CurrentValueSubject<Fee?, Never> = .init(.none)

    private var supportCustomFee: Bool {
        provider.feeOptions.contains(.custom)
    }

    private var bag: Set<AnyCancellable> = []

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        provider: SendFeeProvider,
        customFeeService: CustomFeeService?
    ) {
        self.input = input
        self.output = output
        self.provider = provider
        self.customFeeService = customFeeService

        bind()
    }

    func bind() {
        let suggestedFeeToUse = provider.feesPublisher
            .withWeakCaptureOf(self)
            .compactMap { (interactor: CommonSendFeeInteractor, feesResult: LoadingResult<[SendFee], Error>) in
                switch feesResult {
                case .success(let fees):
                    return interactor.feeForAutoupdate(fees: fees)

                case .failure(let error):
                    return SendFee(option: .market, value: .failure(error))

                case .loading where interactor.input?.selectedFee.value.value == nil:
                    // Show skeleton if currently fee don't have value
                    return SendFee(option: .market, value: .loading)

                case .loading:
                    // Do nothing to exclude jumping skeleton/value
                    return nil
                }
            }
            .share()
            .removeDuplicates()

        suggestedFeeToUse
            // Only once when the fee has value
            .first(where: { $0.value.value != nil })
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                fee.value.value.map {
                    interactor.customFeeService?.initialSetupCustomFee($0)
                }
            }
            .store(in: &bag)

        suggestedFeeToUse
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                interactor.update(selectedFee: fee)
            }
            .store(in: &bag)
    }
}

// MARK: - SendFeeInteractor

extension CommonSendFeeInteractor: SendFeeInteractor {
    var selectedFee: SendFee? {
        input?.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedFeePublisher
    }

    var fees: [SendFee] {
        mapToSendFees(feesValue: provider.fees, customFee: _customFee.value)
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        Publishers.CombineLatest(provider.feesPublisher, _customFee)
            .withWeakCaptureOf(self)
            .map { interactor, args in
                let (feesValue, customFee) = args
                return interactor.mapToSendFees(feesValue: feesValue, customFee: customFee)
            }
            .eraseToAnyPublisher()
    }

    func update(selectedFee: SendFee) {
        output?.feeDidChanged(fee: selectedFee)
    }
}

// MARK: - FeeSelectorContentViewModelInput

extension CommonSendFeeInteractor: FeeSelectorContentViewModelInput {
    var selectedSelectorFee: FeeSelectorFee? {
        mapToFeeSelectorFee(fee: selectedFee)
    }

    var selectedSelectorFeePublisher: AnyPublisher<FeeSelectorFee, Never> {
        selectedFeePublisher
            .withWeakCaptureOf(self)
            .compactMap { $0.mapToFeeSelectorFee(fee: $1) }
            .eraseToAnyPublisher()
    }

    var selectorFees: [FeeSelectorFee] {
        fees.compactMap { mapToFeeSelectorFee(fee: $0) }
    }

    var selectorFeesPublisher: AnyPublisher<LoadingResult<[FeeSelectorFee], Never>, Never> {
        feesPublisher
            .withWeakCaptureOf(self)
            .compactMap { interactor, fees in
                if fees.contains(where: { $0.value.isLoading }) {
                    return .loading
                }

                let selectorFees = fees.compactMap { interactor.mapToFeeSelectorFee(fee: $0) }
                return .success(selectorFees)
            }
            .eraseToAnyPublisher()
    }

    func mapToFeeSelectorFee(fee: SendFee?) -> FeeSelectorFee? {
        guard let fee, let value = fee.value.value else {
            return nil
        }

        return .init(option: fee.option, value: value.amount.value)
    }
}

// MARK: - FeeSelectorContentViewModelOutput

extension CommonSendFeeInteractor: FeeSelectorContentViewModelOutput {
    func update(selectedFeeOption: FeeOption) {
        if let fee = fees.first(where: { $0.option == selectedFeeOption }) {
            update(selectedFee: fee)
        }
    }

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
    func customFeeDidChanged(_ customFee: Fee) {
        _customFee.send(customFee)
    }
}

// MARK: - Private

private extension CommonSendFeeInteractor {
    func mapToSendFees(feesValue: LoadingResult<[SendFee], Error>, customFee: Fee?) -> [SendFee] {
        switch feesValue {
        case .loading:
            return provider.feeOptions.map { SendFee(option: $0, value: .loading) }
        case .success(let fees):
            return mapToFees(fees: fees, customFee: customFee)
        case .failure(let error):
            return provider.feeOptions.map { SendFee(option: $0, value: .failure(error)) }
        }
    }

    func mapToFees(fees: [SendFee], customFee: Fee?) -> [SendFee] {
        // This filter hides the values if we have not passed the default values
        var defaultOptions = fees.filter { provider.feeOptions.contains($0.option) }

        if supportCustomFee {
            let customFee = customFee ?? defaultOptions.first(where: { $0.option == .market })?.value.value

            if let customFee {
                defaultOptions.append(SendFee(option: .custom, value: .success(customFee)))
            }
        }

        return defaultOptions
    }

    private func feeForAutoupdate(fees: [SendFee]) -> SendFee? {
        if let selected = fees.first(where: { $0.option == input?.selectedFee.option }) {
            return selected
        }

        return fees.first(where: { $0.option == .market })
    }
}
