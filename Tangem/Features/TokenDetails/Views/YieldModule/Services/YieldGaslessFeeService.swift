//
//  YieldGaslessFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import BlockchainSdk

final class YieldGaslessFeeService {
    let transactionSender: any GaslessBatchTransactionSending

    private let coinFeeTokenItem: TokenItem
    private let makeTokenFeeProvidersManager: () -> any TokenFeeProvidersManager
    private lazy var tokenFeeProvidersManager: any TokenFeeProvidersManager = makeTokenFeeProvidersManager()
    private let excludedFeeTokenItem = CurrentValueSubject<TokenItem?, Never>(nil)
    private let isUpdatingFees = CurrentValueSubject<Bool, Never>(false)

    init(
        coinFeeTokenItem: TokenItem,
        transactionSender: any GaslessBatchTransactionSending,
        makeTokenFeeProvidersManager: @escaping () -> any TokenFeeProvidersManager
    ) {
        self.coinFeeTokenItem = coinFeeTokenItem
        self.transactionSender = transactionSender
        self.makeTokenFeeProvidersManager = makeTokenFeeProvidersManager
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        tokenFeeProvidersManager.selectedTokenFeePublisher
            .withWeakCaptureOf(self)
            .map { service, tokenFee in service.checkingBalanceCoverage(of: tokenFee) }
            .eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManager.supportFeeSelectionPublisher
    }

    var isUpdatingFeesPublisher: AnyPublisher<Bool, Never> {
        isUpdatingFees.removeDuplicates().eraseToAnyPublisher()
    }

    func updateFees(for transactionFees: [YieldTransactionFee], excludedFeeTokenItem: TokenItem? = nil) async {
        isUpdatingFees.send(true)
        defer { isUpdatingFees.send(false) }

        self.excludedFeeTokenItem.send(excludedFeeTokenItem)
        tokenFeeProvidersManager.updateExcludedFeeProvider(feeTokenItem: excludedFeeTokenItem)

        let estimatedGasLimit = transactionFees
            .flatMap(\.transactionFees)
            .compactMap { ($0.parameters as? EthereumFeeParameters)?.gasLimit }
            .reduce(BigUInt.zero, +)

        tokenFeeProvidersManager.update(
            input: .dex(.ethereumEstimate(estimatedGasLimit: Int(estimatedGasLimit), otherNativeFee: nil))
        )

        await tokenFeeProvidersManager.updateFees().value
    }

    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: tokenFeeProvider.feeTokenItem)
        tokenFeeProvidersManager.updateFees()
    }

    func selectedGaslessFee() throws -> BSDKFee? {
        guard tokenFeeProvidersManager.selectedFeeProvider.feeTokenItem != coinFeeTokenItem else {
            return nil
        }

        return try checkingBalanceCoverage(of: tokenFeeProvidersManager.selectedTokenFee).value.get()
    }
}

// MARK: - Private

private extension YieldGaslessFeeService {
    func checkingBalanceCoverage(of tokenFee: TokenFee) -> TokenFee {
        guard tokenFee.tokenItem != coinFeeTokenItem,
              case .success(let fee) = tokenFee.value,
              let feeProvider = tokenFeeProvidersManager.tokenFeeProviders.first(where: { $0.feeTokenItem == tokenFee.tokenItem }),
              let balance = feeProvider.balanceFeeTokenState.value,
              fee.amount.value > balance else {
            return tokenFee
        }

        return TokenFee(
            option: tokenFee.option,
            tokenItem: tokenFee.tokenItem,
            value: .failure(TokenFeeProviderError.notEnoughGaslessFeeBalance(feeCurrencyBalance: balance))
        )
    }
}

// MARK: - FeeSelectorTokensDataProvider

extension YieldGaslessFeeService: FeeSelectorTokensDataProvider {
    var selectedTokenFeeProvider: any TokenFeeProvider {
        tokenFeeProvidersManager.selectedFeeProvider
    }

    var selectedTokenFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        tokenFeeProvidersManager.selectedFeeProviderPublisher
    }

    var supportedTokenFeeProviders: [any TokenFeeProvider] {
        supportedProviders(excluding: excludedFeeTokenItem.value)
    }

    var supportedTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        let statesChanged = Publishers.MergeMany(tokenFeeProvidersManager.tokenFeeProviders.map(\.statePublisher))
            .map { _ in () }
            .prepend(())

        return Publishers.CombineLatest(statesChanged, excludedFeeTokenItem)
            .withWeakCaptureOf(self)
            .map { service, values in service.supportedProviders(excluding: values.1) }
            .removeDuplicates(by: { $0.map(\.feeTokenItem) == $1.map(\.feeTokenItem) })
            .eraseToAnyPublisher()
    }

    private func supportedProviders(excluding excludedFeeTokenItem: TokenItem?) -> [any TokenFeeProvider] {
        tokenFeeProvidersManager.tokenFeeProviders.filter { $0.state.isSupported && $0.feeTokenItem != excludedFeeTokenItem }
    }
}
