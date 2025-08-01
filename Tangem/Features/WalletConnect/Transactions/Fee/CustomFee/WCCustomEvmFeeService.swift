//
//  WCCustomEvmFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import Combine
import BigInt
import TangemFoundation

class WCCustomEvmFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let sourceTokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let transaction: WalletConnectEthTransaction
    private let walletModel: any WalletModel
    private let validationService: WCTransactionValidationService
    private weak var notificationManager: WCNotificationManager?
    private let onValidationUpdate: ([NotificationViewInput]) -> Void
    private let savedCustomValues: (feeValue: Decimal, gasPrice: Decimal)?
    private let onCustomValueSaved: (Decimal, Decimal) -> Void

    private lazy var customFeeTextField = DecimalNumberTextField.ViewModel(maximumFractionDigits: feeTokenItem.decimalCount)
    private lazy var gasLimitTextField = DecimalNumberTextField.ViewModel(maximumFractionDigits: 0)
    private lazy var gasPriceTextField = DecimalNumberTextField.ViewModel(maximumFractionDigits: Constants.gweiDigits)

    private var isInitializing = true

    private var gasLimit: BigUInt? {
        gasLimitTextField.value
            .flatMap(BigUInt.init(decimal:))
    }

    private var gasPrice: BigUInt? {
        gasPriceTextField.value
            .flatMap { BigUInt(decimal: $0.shiftOrder(magnitude: Constants.gweiDigits)) }
    }

    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
    private var customFeeBeforeEditing: Fee?
    private var customGasPriceBeforeEditing: BigUInt?

    private var zeroFee: Fee {
        return Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    private var bag: Set<AnyCancellable> = []

    init(
        sourceTokenItem: TokenItem,
        feeTokenItem: TokenItem,
        transaction: WalletConnectEthTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        savedCustomValues: (feeValue: Decimal, gasPrice: Decimal)? = nil,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
        onCustomValueSaved: @escaping (Decimal, Decimal) -> Void
    ) {
        self.sourceTokenItem = sourceTokenItem
        self.feeTokenItem = feeTokenItem
        self.transaction = transaction
        self.walletModel = walletModel
        self.validationService = validationService
        self.notificationManager = notificationManager
        self.savedCustomValues = savedCustomValues
        self.onValidationUpdate = onValidationUpdate
        self.onCustomValueSaved = onCustomValueSaved

        bind()
    }

    private func bind() {
        customFee
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.updateView(fee: customFee)

                if !service.isInitializing {
                    service.output?.customFeeDidChanged(customFee)
                }

                service.validateCustomFee(customFee)
            }
            .store(in: &bag)

        customFeeTextField.valuePublisher
            .withWeakCaptureOf(self)
            .sink(receiveValue: { service, value in
                service.customFee.send(service.calculateFee(for: value))
            })
            .store(in: &bag)

        gasPriceTextField.valuePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { service, value in
                service.customFee.send(service.recalculateFee())
                if let gasPrice = value, let feeValue = service.customFeeTextField.value {
                    service.onCustomValueSaved(feeValue, gasPrice)
                }
            })
            .store(in: &bag)
    }

    private func formatToFiat(value: Decimal?) -> String? {
        guard let value, let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }

    private func recalculateFee() -> Fee {
        guard let gasLimit = gasLimit, let gasPrice = gasPrice else {
            return zeroFee
        }

        let parameters: EthereumFeeParameters

        if feeTokenItem.blockchain.supportsEIP1559 {
            parameters = EthereumEIP1559FeeParameters(
                gasLimit: gasLimit,
                maxFeePerGas: gasPrice,
                priorityFee: gasPrice
            )
        } else {
            parameters = EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)
        }

        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func calculateFee(for feeValue: Decimal?) -> Fee {
        let feeDecimalValue = feeTokenItem.decimalValue

        guard let feeValue, let currentGasLimit = gasLimit else {
            return zeroFee
        }

        let enteredFeeInSmallestDenomination = (feeValue * feeDecimalValue).rounded(roundingMode: .down)
        guard let enteredFeeInSmallestDenomination = BigUInt(decimal: enteredFeeInSmallestDenomination) else {
            return zeroFee
        }

        let calculatedGasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)

        let gasPriceInGwei = calculatedGasPrice.decimal?.shiftOrder(magnitude: -Constants.gweiDigits)
        gasPriceTextField.update(value: gasPriceInGwei)

        let parameters: EthereumFeeParameters

        if feeTokenItem.blockchain.supportsEIP1559 {
            parameters = EthereumEIP1559FeeParameters(
                gasLimit: currentGasLimit,
                maxFeePerGas: calculatedGasPrice,
                priorityFee: calculatedGasPrice
            )
        } else {
            parameters = EthereumLegacyFeeParameters(gasLimit: currentGasLimit, gasPrice: calculatedGasPrice)
        }

        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func updateView(fee: Fee?) {
        guard let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters else {
            return
        }

        let feeAmount = fee?.amount.value
        customFeeTextField.update(value: feeAmount)

        switch ethereumFeeParameters.parametersType {
        case .eip1559(let eip1559Parameters):
            gasLimitTextField.update(value: eip1559Parameters.gasLimit.decimal)
            gasPriceTextField.update(value: eip1559Parameters.maxFeePerGas.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
        case .legacy(let legacyParameters):
            gasLimitTextField.update(value: legacyParameters.gasLimit.decimal)
            gasPriceTextField.update(value: legacyParameters.gasPrice.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
        }
    }

    private func updateFieldsFromTransaction() {
        if let gasString = transaction.gas, let gasValue = BigUInt(gasString.removeHexPrefix(), radix: 16) {
            gasLimitTextField.update(value: gasValue.decimal)
        }

        if let gasPriceString = transaction.gasPrice, let gasPriceValue = BigUInt(gasPriceString.removeHexPrefix(), radix: 16) {
            gasPriceTextField.update(value: gasPriceValue.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
        }
    }
}

// MARK: - WCCustomEvmFeeService

protocol WCCustomFeeServiceOutput: CustomFeeServiceOutput {
    func updateCustomFeeForInitialization(_ customFee: Fee)
}

extension WCCustomEvmFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        self.output = output
    }

    func initialSetupCustomFee(_ fee: Fee) {
        isInitializing = true

        customFee.send(fee)

        if let wcOutput = output as? WCCustomFeeServiceOutput {
            wcOutput.updateCustomFeeForInitialization(fee)
        }

        updateView(fee: fee)

        if savedCustomValues != nil {
            restoreSavedCustomValues()
        } else {
            isInitializing = false
        }
    }

    private func restoreSavedCustomValues() {
        guard let savedValues = savedCustomValues else {
            return
        }

        customFeeTextField.update(value: savedValues.feeValue)

        gasPriceTextField.update(value: savedValues.gasPrice)

        let recalculated = recalculateFee()
        customFee.send(recalculated)
    }

    func selectorCustomFeeRowViewModels() -> [FeeSelectorCustomFeeRowViewModel] {
        let customFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendMaxFee,
            suffix: feeTokenItem.currencySymbol,
            isEditable: true,
            textFieldViewModel: customFeeTextField,
            amountAlternativePublisher: customFeeTextField.valuePublisher
                .map { [weak self] value in
                    self?.formatToFiat(value: value)
                }
                .eraseToAnyPublisher(),
            onFocusChanged: { [weak self] focused in
                self?.onCustomFeeChanged(focused)
            }
        )

        let gasLimitRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendGasLimit,
            suffix: nil,
            isEditable: false,
            textFieldViewModel: gasLimitTextField,
            amountAlternativePublisher: Just(nil).eraseToAnyPublisher()
        )

        let gasPriceRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendGasPrice,
            suffix: Constants.gweiSuffix,
            isEditable: true,
            textFieldViewModel: gasPriceTextField,
            amountAlternativePublisher: Just(nil).eraseToAnyPublisher(),
            onFocusChanged: { [weak self] focused in
                self?.onGasPriceChanged(focused)
            }
        )

        let result = [customFeeRowViewModel, gasLimitRowViewModel, gasPriceRowViewModel]

        return result
    }
}

// MARK: - Analytics

private extension WCCustomEvmFeeService {
    private func onCustomFeeChanged(_ focused: Bool) {
        if focused {
            customFeeBeforeEditing = customFee.value
        } else {
            if customFee.value != customFeeBeforeEditing {
                Analytics.log(.sendCustomFeeInserted)
            }
        }
    }

    private func onGasLimitChanged(_ focused: Bool) {}

    private func onGasPriceChanged(_ focused: Bool) {
        if focused {
            customGasPriceBeforeEditing = gasPrice
        } else {
            let customGasPriceAfterEditing = gasPrice
            if customGasPriceAfterEditing != customGasPriceBeforeEditing {
                Analytics.log(.sendGasPriceInserted)
            }

            customGasPriceBeforeEditing = nil
        }
    }

    // MARK: - Private Methods

    private func validateCustomFee(_ customFee: Fee) {
        var allEvents: [WCNotificationEvent] = []

        let feeEvents = validationService.validateCustomFee(customFee, against: nil)
        allEvents.append(contentsOf: feeEvents)

        if let balance = walletModel.availableBalanceProvider.balanceType.value {
            let transactionValue = Decimal(string: transaction.value ?? "") ?? 0
            let balanceEvents = validationService.validateBalance(
                transactionAmount: transactionValue,
                fee: customFee,
                availableBalance: balance
            )
            allEvents.append(contentsOf: balanceEvents)
        }

        if let inputs = notificationManager?.updateFeeValidationNotifications(allEvents) {
            onValidationUpdate(inputs)
        }
    }
}

// MARK: - Private extensions

private extension WCCustomEvmFeeService {
    enum Constants {
        static let gweiDigits: Int = 9
        static let gweiSuffix: String = "GWEI"
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
