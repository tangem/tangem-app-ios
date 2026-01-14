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
import TangemAccessibilityIdentifiers

final class WCCustomEvmFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let sourceTokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let transaction: WCSendableTransaction
    private let walletModel: any WalletModel
    private let validationService: WCTransactionValidationService
    private let notificationManager: WCNotificationManager?
    private let onValidationUpdate: ([NotificationViewInput]) -> Void

    private lazy var customFeeTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: feeTokenItem.decimalCount)
    private lazy var gasLimitTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: 0)
    private lazy var gasPriceTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.gweiDigits)
    private lazy var maxFeePerGasTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.gweiDigits)
    private lazy var priorityFeeTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.gweiDigits)

    private var gasLimit: BigUInt? {
        gasLimitTextField.value
            .flatMap(BigUInt.init(decimal:))
    }

    private var gasPrice: BigUInt? {
        gasPriceTextField.value
            .flatMap { BigUInt(decimal: $0.shiftOrder(magnitude: Constants.gweiDigits)) }
    }

    private var maxFeePerGas: BigUInt? {
        maxFeePerGasTextField.value
            .flatMap { BigUInt(decimal: $0.shiftOrder(magnitude: Constants.gweiDigits)) }
    }

    private var priorityFee: BigUInt? {
        priorityFeeTextField.value
            .flatMap { BigUInt(decimal: $0.shiftOrder(magnitude: Constants.gweiDigits)) }
    }

    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)

    private var customFeeBeforeEditing: Fee?
    private var customGasPriceBeforeEditing: BigUInt?
    private var customMaxFeePerGasBeforeEditing: BigUInt?
    private var customPriorityFeeBeforeEditing: BigUInt?
    private var customMaxLimitBeforeEditing: BigUInt?
    private var customNonceBeforeEditing: Int?

    private var zeroFee: Fee {
        return Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    private var cachedCustomFee: Fee?
    private var bag: Set<AnyCancellable> = []

    init(
        sourceTokenItem: TokenItem,
        feeTokenItem: TokenItem,
        transaction: WCSendableTransaction,
        walletModel: any WalletModel,
        validationService: WCTransactionValidationService,
        notificationManager: WCNotificationManager,
        onValidationUpdate: @escaping ([NotificationViewInput]) -> Void,
    ) {
        self.sourceTokenItem = sourceTokenItem
        self.feeTokenItem = feeTokenItem
        self.transaction = transaction
        self.walletModel = walletModel
        self.validationService = validationService
        self.notificationManager = notificationManager
        self.onValidationUpdate = onValidationUpdate

        bind()
    }

    private func bind() {
        customFee
            .compactMap { $0 }
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.updateView(fee: customFee)
                service.output?.customFeeDidChanged(customFee)
                service.validateCustomFee(customFee)
            }
            .store(in: &bag)

        customFeeTextField.valuePublisher
            .withWeakCaptureOf(self)
            .sink { service, value in
                service.customFee.send(service.calculateFee(for: value))
            }
            .store(in: &bag)

        Publishers.MergeMany(
            gasLimitTextField.valuePublisher.removeDuplicates(),
            gasPriceTextField.valuePublisher.removeDuplicates(),
            maxFeePerGasTextField.valuePublisher.removeDuplicates(),
            priorityFeeTextField.valuePublisher.removeDuplicates(),
        )
        .withWeakCaptureOf(self)
        .sink(receiveValue: { $0.0.customFee.send($0.0.recalculateFee()) })
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
        let parameters: EthereumFeeParameters

        if feeTokenItem.blockchain.supportsEIP1559 {
            guard
                let gasLimit = gasLimit,
                let maxFeePerGas = maxFeePerGas,
                let priorityFee = priorityFee
            else {
                return zeroFee
            }

            parameters = EthereumEIP1559FeeParameters(
                gasLimit: gasLimit,
                maxFeePerGas: maxFeePerGas,
                priorityFee: priorityFee,
                nonce: nil
            )
        } else {
            guard let gasLimit = gasLimit, let gasPrice = gasPrice else {
                return zeroFee
            }

            parameters = EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice, nonce: nil)
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

        let parameters: EthereumFeeParameters

        if feeTokenItem.blockchain.supportsEIP1559, let currentPriorityFee = priorityFee {
            let maxFeePerGas = (enteredFeeInSmallestDenomination / currentGasLimit)
            parameters = EthereumEIP1559FeeParameters(
                gasLimit: currentGasLimit,
                maxFeePerGas: maxFeePerGas,
                priorityFee: currentPriorityFee,
                nonce: nil
            )
        } else {
            let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
            parameters = EthereumLegacyFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice, nonce: nil)
        }

        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func updateView(fee: Fee?) {
        guard let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters else {
            return
        }

        customFeeTextField.update(value: fee?.amount.value)

        switch ethereumFeeParameters.parametersType {
        case .eip1559(let eip1559Parameters):
            gasLimitTextField.update(value: eip1559Parameters.gasLimit.decimal)
            let maxFeeInGwei = eip1559Parameters.maxFeePerGas.decimal?.shiftOrder(magnitude: -Constants.gweiDigits)
            let priorityInGwei = eip1559Parameters.priorityFee.decimal?.shiftOrder(magnitude: -Constants.gweiDigits)

            maxFeePerGasTextField.update(value: maxFeeInGwei)
            priorityFeeTextField.update(value: priorityInGwei)
        case .legacy(let legacyParameters):
            gasLimitTextField.update(value: legacyParameters.gasLimit.decimal)
            gasPriceTextField.update(value: legacyParameters.gasPrice.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
        case .gasless:
            break
        }
    }

    private func updateFieldsFromTransaction() {
        if let gasString = transaction.gas, let gasValue = BigUInt(gasString.removeHexPrefix(), radix: 16) {
            gasLimitTextField.update(value: gasValue.decimal)
        }

        if feeTokenItem.blockchain.supportsEIP1559 {
            if let maxFeePerGasString = transaction.maxFeePerGas,
               let maxFeePerGasValue = BigUInt(maxFeePerGasString.removeHexPrefix(), radix: 16) {
                maxFeePerGasTextField.update(value: maxFeePerGasValue.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
            }

            if let priorityFeeString = transaction.maxPriorityFeePerGas,
               let priorityFeeValue = BigUInt(priorityFeeString.removeHexPrefix(), radix: 16) {
                priorityFeeTextField.update(value: priorityFeeValue.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
            }
        } else {
            if let gasPriceString = transaction.gasPrice,
               let gasPriceValue = BigUInt(gasPriceString.removeHexPrefix(), radix: 16) {
                gasPriceTextField.update(value: gasPriceValue.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
            }
        }
    }

    private func validateCustomFee(_ customFee: Fee) {
        var allEvents: [WCNotificationEvent] = []

        let feeEvents = validationService.validateCustomFee(customFee, against: nil)
        allEvents.append(contentsOf: feeEvents)

        let balance = walletModel.availableBalanceProvider.balanceType.value
        let transactionValue = EthereumUtils.parseEthereumDecimal(transaction.value ?? "0x0", decimalsCount: walletModel.feeTokenItem.decimalCount)

        if let balance, let transactionValue {
            let balanceEvents = validationService.validateBalance(
                transactionAmount: transactionValue,
                fee: customFee,
                availableBalance: balance,
                blockchainName: walletModel.name
            )
            allEvents.append(contentsOf: balanceEvents)
        }

        if let inputs = notificationManager?.updateFeeValidationNotifications(allEvents) {
            onValidationUpdate(inputs)
        }
    }
}

// MARK: - CustomFeeServiceOutput

protocol WCCustomFeeServiceOutput: CustomFeeServiceOutput {
    func updateCustomFeeForInitialization(_ customFee: Fee)
}

// MARK: - FeeSelectorCustomFeeAvailabilityProvider

extension WCCustomEvmFeeService: FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { customFee.value != zeroFee }

    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> {
        customFee
            .withWeakCaptureOf(self)
            .map { $0.zeroFee != $1 }
            .eraseToAnyPublisher()
    }

    func captureCustomFeeFieldsValue() {
        cachedCustomFee = customFee.value
    }

    func resetCustomFeeFieldsValue() {
        updateView(fee: cachedCustomFee)
    }
}

// MARK: - FeeSelectorCustomFeeFieldsBuilder

extension WCCustomEvmFeeService: FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
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
            },
            accessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeTotalAmountField,
            alternativeAmountAccessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeMaxFeeFiatValue
        )

        let gasLimitRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendGasLimit,
            suffix: nil,
            isEditable: true,
            textFieldViewModel: gasLimitTextField,
            amountAlternativePublisher: Just(nil).eraseToAnyPublisher()
        )

        if feeTokenItem.blockchain.supportsEIP1559 {
            let maxFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
                title: Localization.sendCustomEvmMaxFee,
                suffix: Constants.gweiSuffix,
                isEditable: true,
                textFieldViewModel: maxFeePerGasTextField,
                amountAlternativePublisher: Just(nil).eraseToAnyPublisher(),
                onFocusChanged: { [weak self] focused in
                    self?.onMaxFeePerGasChanged(focused)
                }
            )

            let priorityFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
                title: Localization.sendCustomEvmPriorityFee,
                suffix: Constants.gweiSuffix,
                isEditable: true,
                textFieldViewModel: priorityFeeTextField,
                amountAlternativePublisher: Just(nil).eraseToAnyPublisher(),
                onFocusChanged: { [weak self] focused in
                    self?.onPriorityFeeChanged(focused)
                }
            )

            return [customFeeRowViewModel, maxFeeRowViewModel, priorityFeeRowViewModel, gasLimitRowViewModel]
        } else {
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

            return [customFeeRowViewModel, gasPriceRowViewModel, gasLimitRowViewModel]
        }
    }
}

// MARK: - CustomFeeService

extension WCCustomEvmFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        self.output = output
    }

    func initialSetupCustomFee(_ fee: Fee) {
        assert(customFee.value == nil, "Duplicate initial setup")

        customFee.send(fee)
        updateView(fee: fee)
    }
}

private extension WCCustomEvmFeeService {
    private func onCustomFeeChanged(_ focused: Bool) {
        if focused {
            customFeeBeforeEditing = customFee.value
        }
    }

    private func onMaxFeePerGasChanged(_ focused: Bool) {
        if focused {
            customMaxFeePerGasBeforeEditing = maxFeePerGas
        } else {
            customMaxFeePerGasBeforeEditing = nil
        }
    }

    private func onPriorityFeeChanged(_ focused: Bool) {
        if focused {
            customPriorityFeeBeforeEditing = priorityFee
        } else {
            customPriorityFeeBeforeEditing = nil
        }
    }

    private func onGasLimitChanged(_ focused: Bool) {
        if focused {
            customMaxLimitBeforeEditing = gasLimit
        } else {
            customMaxLimitBeforeEditing = nil
        }
    }

    private func onGasPriceChanged(_ focused: Bool) {
        if focused {
            customGasPriceBeforeEditing = gasPrice
        } else {
            customGasPriceBeforeEditing = nil
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
