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
        for transaction: WCSendableTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        output: WCFeeInteractorOutput?
    ) async -> any WCFeeInteractorType

    func createFeeSelector(
        walletModel: any WalletModel,
        feeInteractor: WCFeeInteractor,
        output: WCFeeInteractorOutput?
    ) -> FeeSelectorContentViewModel

    func updateTransactionWithFee(
        _ fee: WCFee,
        currentTransaction: WCSendableTransaction
    ) -> WCSendableTransaction?

    // MARK: - New WCSendableTransaction overloads

    func validateFeeAndBalance(
        fee: Fee,
        transaction: WCSendableTransaction,
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
        for transaction: WCSendableTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        output: WCFeeInteractorOutput?
    ) async -> any WCFeeInteractorType {
        let networkId = walletModel.feeTokenItem.blockchain.networkId

        let lastSelectedOption = await feeRepository.getLastSelectedFeeOption(for: networkId)
        let suggestedFee = await feeRepository.getSuggestedFeeFromDApp(
            for: networkId,
            blockchain: walletModel.feeTokenItem.blockchain
        )

        let customFeeService = WCCustomEvmFeeService(
            sourceTokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            transaction: transaction,
            walletModel: walletModel,
            validationService: validationService,
            notificationManager: notificationManager,
            onValidationUpdate: onValidationUpdate
        )

        let wcFeeInteractor = WCFeeInteractor(
            transaction: transaction,
            walletModel: walletModel,
            customFeeService: customFeeService,
            initialFeeOption: lastSelectedOption,
            feeRepository: feeRepository,
            suggestedFee: suggestedFee,

            output: output
        )

        return wcFeeInteractor
    }

    func createFeeSelector(
        walletModel: any WalletModel,
        feeInteractor: WCFeeInteractor,
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
        currentTransaction: WCSendableTransaction
    ) -> WCSendableTransaction? {
        guard let feeValue = fee.value.value, let feeParameters = feeValue.parameters as? EthereumFeeParameters else {
            return nil
        }

        var updatedTransaction: WCSendableTransaction

        switch feeParameters.parametersType {
        case .eip1559(let params):
            updatedTransaction = WCSendableTransaction(
                from: currentTransaction.from,
                to: currentTransaction.to,
                value: currentTransaction.value,
                data: currentTransaction.data,
                gas: String(params.gasLimit, radix: 16).addHexPrefix(),
                gasPrice: nil,
                maxFeePerGas: String(params.maxFeePerGas, radix: 16).addHexPrefix(),
                maxPriorityFeePerGas: String(params.priorityFee, radix: 16).addHexPrefix(),
                nonce: currentTransaction.nonce
            )
        case .legacy(let params):
            updatedTransaction = WCSendableTransaction(
                from: currentTransaction.from,
                to: currentTransaction.to,
                value: currentTransaction.value,
                data: currentTransaction.data,
                gas: String(params.gasLimit, radix: 16).addHexPrefix(),
                gasPrice: String(params.gasPrice, radix: 16).addHexPrefix(),
                maxFeePerGas: nil,
                maxPriorityFeePerGas: nil,
                nonce: currentTransaction.nonce
            )
        }

        return updatedTransaction
    }

    func validateFeeAndBalance(
        fee: Fee,
        transaction: WCSendableTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        feeInteractor: any WCFeeInteractorType,
        selectedFeeOption: FeeOption
    ) -> [WCNotificationEvent] {
        var events: [WCNotificationEvent] = []

        let transactionAmount: Decimal
        if let valueString = transaction.value, !valueString.isEmpty, valueString != "0x0" {
            let blockchain = walletModel.tokenItem.blockchain
            transactionAmount = EthereumUtils.parseEthereumDecimal(valueString, decimalsCount: blockchain.decimalCount) ?? 0
        } else {
            transactionAmount = 0
        }

        let balanceEvents = validationService.validateBalance(
            transactionAmount: transactionAmount,
            fee: fee,
            availableBalance: walletModel.availableBalanceProvider.balanceType.value ?? 0,
            blockchainName: walletModel.name
        )
        events.append(contentsOf: balanceEvents)

        let lowFeeEvents = validationService.validateCustomFeeTooLow(
            fee,
            against: feeInteractor.fees.first(where: { $0.option == .slow })?.value.value
        )
        events.append(contentsOf: lowFeeEvents)

        let highFeeEvents = validationService.validateCustomFeeTooHigh(
            fee,
            against: feeInteractor.fees.first(where: { $0.option == .fast })?.value.value
        )
        events.append(contentsOf: highFeeEvents)

        if case .failure = feeInteractor.selectedFee.value {
            events.append(.networkFeeUnreachable)
        }

        return events
    }

    func getHighestNetworkFee(from feeInteractor: any WCFeeInteractorType) -> Fee? {
        let loadedFees = feeInteractor.fees.compactMap { $0.value.value }
        return loadedFees.max { $0.amount.value < $1.amount.value }
    }
}
