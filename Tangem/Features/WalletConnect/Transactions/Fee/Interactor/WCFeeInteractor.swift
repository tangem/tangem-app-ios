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
import BigInt

final class WCFeeInteractor: WCFeeInteractorType {
    // MARK: - Dependencies

    let customFeeService: WCCustomEvmFeeService

    private let transaction: WalletConnectEthTransaction
    private let walletModel: any WalletModel
    private let feeRepository: any WCTransactionFeePreferencesRepository

    weak var output: WCFeeInteractorOutput?

    // MARK: - Reactive Properties

    private let networkFeesSubject: CurrentValueSubject<LoadingValue<[Fee]>, Never> = .init(.loading)
    private let selectedFeeSubject: CurrentValueSubject<WCFee, Never>
    private let customFeeSubject: CurrentValueSubject<Fee?, Never> = .init(.none)

    var selectedFee: WCFee {
        return selectedFeeSubject.value
    }

    var fees: [WCFee] {
        let customFee = customFeeSubject.value
        return mapToWCFees(feesValue: networkFeesSubject.value, customFee: customFee)
    }

    // MARK: - Publishers for external subscription

    var selectedFeePublisher: AnyPublisher<WCFee, Never> {
        selectedFeeSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let initialFeeOption: FeeOption
    private let defaultFeeOptions: [FeeOption] = [.slow, .market, .fast, .custom]

    private let hasSuggestedFee: Bool
    private var bag: Set<AnyCancellable> = []

    // MARK: - Initialization

    init(
        transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        customFeeService: WCCustomEvmFeeService,
        initialFeeOption: FeeOption = .market,
        feeRepository: any WCTransactionFeePreferencesRepository,
        hasSuggestedFee: Bool,
        output: WCFeeInteractorOutput?
    ) {
        self.transaction = transaction
        self.walletModel = walletModel
        self.customFeeService = customFeeService
        self.initialFeeOption = initialFeeOption
        self.feeRepository = feeRepository
        self.output = output
        self.hasSuggestedFee = hasSuggestedFee

        selectedFeeSubject = .init(.init(option: initialFeeOption, value: .loading))

        self.customFeeService.setup(output: self)
        bind()
        loadFees()
    }

    // MARK: - Private Methods

    private func bind() {
        selectedFeeSubject
            .withWeakCaptureOf(self)
            .sink { interactor, selectedFee in
                guard case .loaded = selectedFee.value else {
                    return
                }

                Task {
                    await interactor.feeRepository.saveSelectedFeeOption(
                        selectedFee.option,
                        for: interactor.walletModel.tokenItem.blockchain.networkId
                    )

                    interactor.output?.feeDidChanged(fee: selectedFee)
                }
            }
            .store(in: &bag)
    }

    private func loadFees() {
        guard let ethereumProvider = walletModel.ethereumNetworkProvider else {
            handleFeeLoadingError(WCFeeInteractorError.feeLoadingFailed)
            return
        }

        let transactionData = Data(hexString: transaction.data)

        let feePublisher = ethereumProvider.getFee(
            destination: transaction.to,
            value: transaction.value,
            data: transactionData
        )

        feePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.handleFeeLoadingError(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] networkFees in
                    guard let self else { return }

                    networkFeesSubject.send(.loaded(networkFees))
                    updateCustomFeeWithNetworkData(fees: networkFees)
                    updateSelectedFeeWithNetworkData(fees: networkFees)
                }
            )
            .store(in: &bag)
    }

    private func updateSelectedFeeWithNetworkData(fees: [Fee]) {
        let currentSelectedFee = selectedFeeSubject.value

        if case .loading = currentSelectedFee.value {
            if let networkFee = getFeeForOption(currentSelectedFee.option, from: fees) {
                let updatedFee = WCFee(option: currentSelectedFee.option, value: .loaded(networkFee))
                selectedFeeSubject.send(updatedFee)
            }
        }
    }

    private func getFeeForOption(_ option: FeeOption, from fees: [Fee]) -> Fee? {
        switch option {
        case .suggestedByDApp:
            return fees.count > 3 ? fees[0] : nil
        case .slow:
            let slowIndex = fees.count > 3 ? 1 : 0
            return fees.indices.contains(slowIndex) ? fees[slowIndex] : fees.first
        case .market:
            let marketIndex = fees.count > 3 ? 2 : 1
            return fees.indices.contains(marketIndex) ? fees[marketIndex] : fees.first
        case .fast:
            let fastIndex = fees.count > 3 ? 3 : 2
            return fees.indices.contains(fastIndex) ? fees[fastIndex] : fees.last
        case .custom:
            return nil
        }
    }

    private func updateCustomFeeWithNetworkData(fees: [Fee]) {
        guard fees.count >= 2 else { return }

        let marketFee = fees[1]
        customFeeService.initialSetupCustomFee(marketFee)
    }

    private func getGasLimitFromTransaction() -> BigUInt {
        if let gasString = transaction.gas, let gasValue = BigUInt(gasString.removeHexPrefix(), radix: 16) {
            return gasValue
        }
        return BigUInt(21000)
    }

    private func getGasPriceFromTransaction() -> BigUInt {
        if let gasPrice = transaction.gasPrice, let gasPriceValue = BigUInt(gasPrice.removeHexPrefix(), radix: 16) {
            return gasPriceValue
        }

        return BigUInt(20000000000)
    }

    private func createEIP1559Fee(gasLimit: BigUInt, maxFeePerGas: BigUInt, priorityFee: BigUInt, blockchain: Blockchain) -> Fee {
        let parameters = EthereumEIP1559FeeParameters(
            gasLimit: gasLimit,
            maxFeePerGas: maxFeePerGas,
            priorityFee: priorityFee
        )

        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let amount = Amount(with: blockchain, value: feeValue)

        return Fee(amount, parameters: parameters)
    }

    private func createLegacyFee(gasLimit: BigUInt, gasPrice: BigUInt, blockchain: Blockchain) -> Fee {
        let parameters = EthereumLegacyFeeParameters(
            gasLimit: gasLimit,
            gasPrice: gasPrice
        )

        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let amount = Amount(with: blockchain, value: feeValue)

        return Fee(amount, parameters: parameters)
    }

    private func makeFeeOptions() -> [FeeOption] {
        var options: [FeeOption] = []

        if hasSuggestedFee {
            options.append(.suggestedByDApp(dappName: feeRepository.dappName))
        }

        options.append(contentsOf: defaultFeeOptions)
        return options
    }

    private func mapToWCFees(feesValue: LoadingValue<[Fee]>, customFee: Fee?) -> [WCFee] {
        let feeOptions = makeFeeOptions()

        switch feesValue {
        case .loading:
            let loadingFees = feeOptions.map { WCFee(option: $0, value: .loading) }

            return loadingFees

        case .loaded(let fees):
            var wcFees: [WCFee] = []
            let availableOptions = feeOptions

            var feeIndex = 0

            for option in availableOptions {
                if option == .suggestedByDApp(dappName: feeRepository.dappName) {
                    if fees.count > 3, let suggestedFee = fees.first {
                        wcFees.append(WCFee(option: option, value: .loaded(suggestedFee)))
                    } else {
                        wcFees.append(WCFee(option: option, value: .loading))
                    }
                } else if option == .custom {
                    if let customFee = customFee {
                        wcFees.append(WCFee(option: .custom, value: .loaded(customFee)))
                    } else {
                        wcFees.append(WCFee(option: .custom, value: .loading))
                    }
                } else {
                    let targetIndex = fees.count > 3 ? feeIndex + 1 : feeIndex
                    if targetIndex < fees.count {
                        wcFees.append(WCFee(option: option, value: .loaded(fees[targetIndex])))
                    } else if let lastFee = fees.last {
                        wcFees.append(WCFee(option: option, value: .loaded(lastFee)))
                    }
                    feeIndex += 1
                }
            }

            return wcFees

        case .failedToLoad:
            let failedFees = defaultFeeOptions.map { option in
                WCFee(option: option, value: .failedToLoad(error: WCFeeInteractorError.feeLoadingFailed))
            }

            return failedFees
        }
    }

    // MARK: - Helper Methods

    private func mapToFeeSelectorFee(fee: WCFee) -> FeeSelectorFee? {
        guard case .loaded(let feeValue) = fee.value else {
            return nil
        }

        return FeeSelectorFee(
            option: fee.option,
            value: feeValue.amount.value
        )
    }

    private func handleFeeLoadingError(_ error: Error) {
        let currentSelectedFee = selectedFeeSubject.value
        let failedFee = WCFee(option: currentSelectedFee.option, value: .failedToLoad(error: error))
        selectedFeeSubject.send(failedFee)

        networkFeesSubject.send(.failedToLoad(error: error))
    }

    func retryFeeLoading() {
        let currentSelectedFee = selectedFeeSubject.value
        let loadingFee = WCFee(option: currentSelectedFee.option, value: .loading)
        selectedFeeSubject.send(loadingFee)

        networkFeesSubject.send(.loading)
        loadFees()
    }
}

// MARK: - CustomFeeServiceOutput

extension WCFeeInteractor: WCCustomFeeServiceOutput {
    func customFeeDidChanged(_ customFee: Fee) {
        customFeeSubject.send(customFee)

        let customWCFee = WCFee(option: .custom, value: .loaded(customFee))
        selectedFeeSubject.send(customWCFee)
    }

    func updateCustomFeeForInitialization(_ customFee: Fee) {
        customFeeSubject.send(customFee)
    }
}

// MARK: - Errors

enum WCFeeInteractorError: Error {
    case feeLoadingFailed
}

extension WCFeeInteractor: FeeSelectorContentViewModelInput {
    var feesPublisher: AnyPublisher<[WCFee], Never> {
        Publishers.CombineLatest(networkFeesSubject, customFeeSubject)
            .withWeakCaptureOf(self)
            .map { interactor, args in
                let (feesValue, customFee) = args
                return interactor.mapToWCFees(feesValue: feesValue, customFee: customFee)
            }
            .eraseToAnyPublisher()
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

    var selectedSelectorFee: FeeSelectorFee? {
        let fee = mapToFeeSelectorFee(fee: selectedFee)
        return fee
    }

    var selectedSelectorFeePublisher: AnyPublisher<FeeSelectorFee, Never> {
        selectedFeePublisher
            .withWeakCaptureOf(self)
            .compactMap { interactor, wcFee in
                return interactor.mapToFeeSelectorFee(fee: wcFee)
            }
            .eraseToAnyPublisher()
    }

    var selectorFees: [FeeSelectorFee] {
        let wcFees = fees
        let selectorFees = wcFees.compactMap { mapToFeeSelectorFee(fee: $0) }
        return selectorFees
    }
}

extension WCFeeInteractor: FeeSelectorContentViewModelOutput {
    func update(selectedSelectorFee: FeeSelectorFee) {
        guard let wcFee = fees.first(where: { $0.option == selectedSelectorFee.option }) else {
            return
        }

        selectedFeeSubject.send(wcFee)
    }

    func dismissFeeSelector() {
        output?.returnToTransactionDetails()
    }

    func completeFeeSelection() {
        output?.returnToTransactionDetails()
    }
}
