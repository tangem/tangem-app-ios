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

    private let transaction: WCSendableTransaction
    private let walletModel: any WalletModel
    private let feeRepository: any WCTransactionFeePreferencesRepository

    weak var output: WCFeeInteractorOutput?

    // MARK: - Reactive Properties

    private let networkFeesSubject: CurrentValueSubject<LoadingResult<[WCFee], Error>, Never> = .init(.loading)
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

    private let defaultFeeOptions: [FeeOption] = [.slow, .market, .fast]

    private let suggestedFee: Fee?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Initialization

    init(
        transaction: WCSendableTransaction,
        walletModel: any WalletModel,
        customFeeService: WCCustomEvmFeeService,
        initialFeeOption: FeeOption = .market,
        feeRepository: any WCTransactionFeePreferencesRepository,
        suggestedFee: Fee?,
        output: WCFeeInteractorOutput?
    ) {
        self.transaction = transaction
        self.walletModel = walletModel
        self.customFeeService = customFeeService
        self.feeRepository = feeRepository
        self.output = output
        self.suggestedFee = suggestedFee

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
                interactor.output?.feeDidChanged(fee: selectedFee)

                Task {
                    await interactor.feeRepository.saveSelectedFeeOption(
                        selectedFee.option,
                        for: interactor.walletModel.tokenItem.blockchain.networkId
                    )
                }
            }
            .store(in: &bag)
    }

    private func loadFees() {
        guard let ethereumProvider = walletModel.ethereumNetworkProvider else {
            handleFeeLoadingError(WCFeeInteractorError.feeLoadingFailed)
            return
        }

        let transactionData = Data(hexString: transaction.data ?? "0x")

        let feePublisher = ethereumProvider.getFee(
            destination: transaction.to,
            value: normalizeZeroHex(transaction.value ?? "0x0"),
            data: transactionData
        )

        feePublisher
            .receiveOnMain()
            .mapToResult()
            .withWeakCaptureOf(self)
            .sink { interactor, result in
                switch result {
                case .success(let fees):
                    let defaultWCFees = interactor.mapToDefaultFees(fees: fees)
                    let networkFees = interactor.mapToFees(fees: defaultWCFees, customFee: nil)
                    interactor.networkFeesSubject.send(.success(networkFees))
                    interactor.updateSelectedFeeWithNetworkData(fees: networkFees)
                    interactor.updateCustomFeeWithNetworkData(fees: fees)
                case .failure(let error):
                    WCLogger.error("WC fee loading error", error: error)
                    interactor.handleFeeLoadingError(error)
                }
            }
            .store(in: &bag)
    }

    private func updateSelectedFeeWithNetworkData(fees: [WCFee]) {
        let currentSelectedFee = selectedFeeSubject.value

        if case .loading = currentSelectedFee.value {
            if let networkFee = fees.first(where: { $0.option == currentSelectedFee.option }) {
                selectedFeeSubject.send(networkFee)
            }
        }
    }

    private func getFeeForOption(_ option: FeeOption, from fees: [WCFee]) -> WCFee? {
        switch option {
        case .custom:
            return nil
        default:
            return fees.first { $0.option == option }
        }
    }

    private func updateCustomFeeWithNetworkData(fees: [Fee]) {
        guard fees.count >= 3 else { return }

        let defaultFee = fees[1]
        customFeeService.initialSetupCustomFee(defaultFee)
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

        if suggestedFee != nil {
            options.append(.suggestedByDApp(dappName: feeRepository.dappName))
        }

        options.append(contentsOf: defaultFeeOptions)
        return options
    }

    func mapToWCFees(feesValue: LoadingResult<[WCFee], Error>, customFee: Fee?) -> [WCFee] {
        let feeOptions = makeFeeOptions()

        switch feesValue {
        case .loading:
            return feeOptions.map { WCFee(option: $0, value: .loading) }
        case .success(let fees):
            return mapToFees(fees: fees, customFee: customFee)
        case .failure(let error):
            return feeOptions.map { WCFee(option: $0, value: .failedToLoad(error: error)) }
        }
    }

    func mapToFees(fees: [WCFee], customFee: Fee?) -> [WCFee] {
        let feeOptions = makeFeeOptions()

        var defaultOptions = fees.filter { feeOptions.contains($0.option) }

        let suggestedFeeOption = feeOptions.first { $0 == .suggestedByDApp(dappName: feeRepository.dappName) }
        let customFee = customFee ?? defaultOptions.first(where: { $0.option == .market })?.value.value

        if let suggestedFeeOption, let suggestedFee, (!fees.contains { $0.option == suggestedFeeOption }) {
            defaultOptions.insert(
                .init(
                    option: suggestedFeeOption,
                    value: .loaded(suggestedFee)
                ),
                at: 0
            )
        }

        if let customFee {
            defaultOptions.append(WCFee(option: .custom, value: .loaded(customFee)))
        }

        return defaultOptions
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

        networkFeesSubject.send(.failure(error))
    }

    func retryFeeLoading() {
        let currentSelectedFee = selectedFeeSubject.value
        let loadingFee = WCFee(option: currentSelectedFee.option, value: .loading)
        selectedFeeSubject.send(loadingFee)

        networkFeesSubject.send(.loading)
        loadFees()
    }

    func mapToDefaultFees(fees: [BSDKFee]) -> [WCFee] {
        switch fees.count {
        case 1:
            return [
                WCFee(option: .market, value: .loaded(fees[0])),
            ]
        case 2:
            return [
                WCFee(option: .market, value: .loaded(fees[0])),
                WCFee(option: .fast, value: .loaded(fees[1])),
            ]
        case 3:
            return [
                WCFee(option: .slow, value: .loaded(fees[0])),
                WCFee(option: .market, value: .loaded(fees[1])),
                WCFee(option: .fast, value: .loaded(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
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
    func update(selectedFeeOption: FeeOption) {
        guard let wcFee = fees.first(where: { $0.option == selectedFeeOption }) else {
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

extension WCFeeInteractor {
    private func normalizeZeroHex(_ hex: String) -> String {
        let unhexedValue = hex.removeHexPrefix()

        if unhexedValue.allSatisfy({ $0 == "0" }) {
            return Constants.zeroHex
        }

        return hex
    }
}

private enum Constants {
    static let zeroHex = "0x0"
}
