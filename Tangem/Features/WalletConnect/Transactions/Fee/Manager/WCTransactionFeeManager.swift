//
//  WCTransactionFeeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt

protocol WCTransactionFeeManager {
    var feeRepository: any WCTransactionFeePreferencesRepository { get }

    func setupFeeManagement(
        for transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        onFeeChanged: @escaping (WCFee) -> Void,
        output: WCFeeInteractorOutput?
    ) async -> any WCFeeInteractorType

    func createFeeSelector(
        for transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        feeInteractor: WCFeeInteractor,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        output: WCFeeInteractorOutput?
    ) -> FeeSelectorContentViewModel

    func updateTransactionWithFee(
        _ fee: WCFee,
        currentTransaction: WalletConnectEthTransaction
    ) -> WalletConnectEthTransaction?

    func validateFeeAndBalance(
        fee: Fee,
        transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        feeInteractor: any WCFeeInteractorType,
        selectedFeeOption: FeeOption
    ) -> [WCNotificationEvent]

    func getHighestNetworkFee(from feeInteractor: any WCFeeInteractorType) -> Fee?
}

final class CommonWCTransactionFeeManager: WCTransactionFeeManager {
    let feeRepository: any WCTransactionFeePreferencesRepository

    private let feeSelectorFactory: WCFeeSelectorFactory

    init(
        feeSelectorFactory: WCFeeSelectorFactory = WCFeeSelectorFactory(),
        feeRepository: any WCTransactionFeePreferencesRepository
    ) {
        self.feeSelectorFactory = feeSelectorFactory
        self.feeRepository = feeRepository
    }

    func setupFeeManagement(
        for transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        onFeeChanged: @escaping (WCFee) -> Void,
        output: WCFeeInteractorOutput?
    ) async -> any WCFeeInteractorType {
        let networkId = walletModel.tokenItem.blockchain.networkId

        let lastSelectedOption = await feeRepository.getLastSelectedFeeOption(for: networkId)
        let lastCustomValues = await feeRepository.getLastCustomFeeValues(for: networkId)
        let hasSuggestedFee = await feeRepository.getSuggestedFeeFromDApp(for: networkId) != nil

        let customFeeService = WCCustomEvmFeeService(
            sourceTokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            transaction: transaction,
            walletModel: walletModel,
            validationService: validationService,
            notificationManager: notificationManager,
            savedCustomValues: lastCustomValues,
            onValidationUpdate: onValidationUpdate,
            onCustomValueSaved: { [weak self] feeValue, gasPrice in
                Task {
                    await self?.feeRepository.saveCustomFeeValues((feeValue: feeValue, gasPrice: gasPrice), for: networkId)
                }
            }
        )

        let wcFeeInteractor = WCFeeInteractor(
            transaction: transaction,
            walletModel: walletModel,
            customFeeService: customFeeService,
            initialFeeOption: lastSelectedOption,
            feeRepository: feeRepository,
            hasSuggestedFee: hasSuggestedFee,
            output: output
        )

        return wcFeeInteractor
    }

    func createFeeSelector(
        for transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        feeInteractor: WCFeeInteractor,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        output: WCFeeInteractorOutput?
    ) -> FeeSelectorContentViewModel {
        return feeSelectorFactory.createFeeSelector(
            customFeeService: feeInteractor.customFeeService,
            walletModel: walletModel,
            feeInteractor: feeInteractor
        )
    }

    func updateTransactionWithFee(
        _ fee: WCFee,
        currentTransaction: WalletConnectEthTransaction
    ) -> WalletConnectEthTransaction? {
        guard let feeValue = fee.value.value,
              let feeParameters = feeValue.parameters as? EthereumFeeParameters else {
            return nil
        }

        var updatedTransaction = currentTransaction

        switch feeParameters.parametersType {
        case .eip1559(let params):
            updatedTransaction = WalletConnectEthTransaction(
                from: currentTransaction.from,
                to: currentTransaction.to,
                value: currentTransaction.value,
                data: currentTransaction.data,
                gas: String(params.gasLimit, radix: 16).addHexPrefix(),
                gasPrice: String(params.maxFeePerGas, radix: 16).addHexPrefix(),
                nonce: currentTransaction.nonce
            )
        case .legacy(let params):
            updatedTransaction = WalletConnectEthTransaction(
                from: currentTransaction.from,
                to: currentTransaction.to,
                value: currentTransaction.value,
                data: currentTransaction.data,
                gas: String(params.gasLimit, radix: 16).addHexPrefix(),
                gasPrice: String(params.gasPrice, radix: 16).addHexPrefix(),
                nonce: currentTransaction.nonce
            )
        }

        return updatedTransaction
    }

    func validateFeeAndBalance(
        fee: Fee,
        transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        feeInteractor: any WCFeeInteractorType,
        selectedFeeOption: FeeOption
    ) -> [WCNotificationEvent] {
        var events: [WCNotificationEvent] = []

        let transactionAmount: Decimal
        if let valueString = transaction.value, !valueString.isEmpty, valueString != "0x0" {
            let cleanValue = valueString.hasPrefix("0x") ? String(valueString.dropFirst(2)) : valueString
            if let intValue = Int(cleanValue, radix: 16) {
                let weiAmount = Decimal(intValue)
                let divisor = Decimal(sign: .plus, exponent: -18, significand: 1)
                transactionAmount = weiAmount * divisor
            } else {
                transactionAmount = 0
            }
        } else {
            transactionAmount = 0
        }

        let balanceEvents = validationService.validateBalance(
            transactionAmount: transactionAmount,
            fee: fee,
            availableBalance: walletModel.availableBalanceProvider.balanceType.value ?? 0
        )
        events.append(contentsOf: balanceEvents)

        let highFeeEvents = validationService.validateCustomFeeTooHigh(
            fee,
            against: getHighestNetworkFee(from: feeInteractor)
        )
        events.append(contentsOf: highFeeEvents)

        if selectedFeeOption == .custom {
            let lowFeeEvents = validationService.validateCustomFeeTooLow(
                fee,
                against: getHighestNetworkFee(from: feeInteractor)
            )
            events.append(contentsOf: lowFeeEvents)
        }

        return events
    }

    func getHighestNetworkFee(from feeInteractor: any WCFeeInteractorType) -> Fee? {
        let loadedFees = feeInteractor.fees.compactMap { $0.value.value }
        return loadedFees.max { $0.amount.value < $1.amount.value }
    }
}
