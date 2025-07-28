//
//  WCFeeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

struct WCFee: Hashable {
    let option: FeeOption
    let value: LoadingValue<Fee>
}

protocol WCFeeInteractorOutput: AnyObject {
    func feeDidChanged(fee: WCFee)

    @MainActor
    func returnToTransactionDetails()
}

final class WCFeeInteractor {
    // MARK: - Dependencies

    private let transaction: WalletConnectEthTransaction
    private let walletModel: any WalletModel
    private let feeProvider: WCFeeProvider
    private weak var output: WCFeeInteractorOutput?

    // MARK: - Private Properties

    private let _fees = CurrentValueSubject<LoadingValue<[Fee]>, Never>(.loading)
    private let _selectedFee = CurrentValueSubject<WCFee, Never>(.init(option: .market, value: .loading))

    private let defaultFeeOptions: [FeeOption] = [.slow, .market, .fast, .custom]

    private var bag: Set<AnyCancellable> = []

    // MARK: - Initialization

    init(
        transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        feeProvider: WCFeeProvider,
        output: WCFeeInteractorOutput?
    ) {
        self.transaction = transaction
        self.walletModel = walletModel
        self.feeProvider = feeProvider
        self.output = output

        bind()
        loadFees()
    }

    // MARK: - Public Interface

    var selectedFee: WCFee {
        _selectedFee.value
    }

    var selectedFeePublisher: AnyPublisher<WCFee, Never> {
        _selectedFee.eraseToAnyPublisher()
    }

    var fees: [WCFee] {
        mapToWCFees(feesValue: _fees.value)
    }

    var feesPublisher: AnyPublisher<[WCFee], Never> {
        _fees
            .withWeakCaptureOf(self)
            .map { interactor, feesValue in
                interactor.mapToWCFees(feesValue: feesValue)
            }
            .eraseToAnyPublisher()
    }

    func update(selectedFee: WCFee) {
        _selectedFee.send(selectedFee)
        output?.feeDidChanged(fee: selectedFee)
    }

    func loadFees() {
        if _fees.value.error != nil {
            _fees.send(.loading)
        }

        feeProvider
            .getFee(for: transaction, walletModel: walletModel)
            .mapToResult()
            .withWeakCaptureOf(self)
            .sink { interactor, result in
                switch result {
                case .success(let fees):
                    interactor._fees.send(.loaded(fees))
                case .failure(let error):
                    interactor._fees.send(.failedToLoad(error: error))
                }
            }
            .store(in: &bag)
    }

    // MARK: - Private Methods

    private func bind() {
        let suggestedFeeToUse = _fees
            .withWeakCaptureOf(self)
            .compactMap { interactor, fees in
                switch fees {
                case .loaded(let fees):
                    return interactor.feeForAutoupdate(fees: fees)
                case .failedToLoad(let error):
                    return WCFee(option: .market, value: .failedToLoad(error: error))
                case .loading where interactor._selectedFee.value.value.value == nil:
                    return WCFee(option: .market, value: .loading)
                case .loading:
                    return nil
                }
            }
            .share()

        suggestedFeeToUse
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                interactor.autoupdateSelectedFee(fee: fee)
            }
            .store(in: &bag)
    }

    private func mapToWCFees(feesValue: LoadingValue<[Fee]>) -> [WCFee] {
        switch feesValue {
        case .loading:
            return defaultFeeOptions.map { WCFee(option: $0, value: .loading) }
        case .loaded(let fees):
            return mapToDefaultFees(fees: fees)
        case .failedToLoad(let error):
            return defaultFeeOptions.map { WCFee(option: $0, value: .failedToLoad(error: error)) }
        }
    }

    private func mapToDefaultFees(fees: [Fee]) -> [WCFee] {
        switch fees.count {
        case 1:
            return [WCFee(option: .market, value: .loaded(fees[0]))]
        case 3:
            return [
                WCFee(option: .slow, value: .loaded(fees[0])),
                WCFee(option: .market, value: .loaded(fees[1])),
                WCFee(option: .fast, value: .loaded(fees[2])),
            ]
        default:
            // Fallback: create only market fee
            return [WCFee(option: .market, value: fees.first.map { .loaded($0) } ?? .loading)]
        }
    }

    private func feeForAutoupdate(fees: [Fee]) -> WCFee? {
        let values = mapToDefaultFees(fees: fees)
        let selectedOption = _selectedFee.value.option
        return values.first(where: { $0.option == selectedOption }) ?? values.first(where: { $0.option == .market })
    }

    private func autoupdateSelectedFee(fee: WCFee) {
        _selectedFee.send(fee)
        output?.feeDidChanged(fee: fee)
    }
}

// MARK: - FeeSelectorContentViewModelInput

extension WCFeeInteractor: FeeSelectorContentViewModelInput {
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

    private func mapToFeeSelectorFee(fee: WCFee) -> FeeSelectorFee? {
        guard let value = fee.value.value else {
            return nil
        }

        return .init(option: fee.option, value: value.amount.value)
    }
}

// MARK: - FeeSelectorContentViewModelOutput

extension WCFeeInteractor: FeeSelectorContentViewModelOutput {
    func update(selectedSelectorFee: FeeSelectorFee) {
        if let wcFee = fees.first(where: { $0.option == selectedSelectorFee.option }) {
            update(selectedFee: wcFee)
        }
    }

    func dismissFeeSelector() {
        Task { @MainActor in
            output?.returnToTransactionDetails()
        }
    }

    func completeFeeSelection() {
        Task { @MainActor in
            output?.returnToTransactionDetails()
        }
    }
}
