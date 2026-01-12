//
//  EVMCustomFeeService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import Combine
import BigInt
import TangemAccessibilityIdentifiers

class EVMCustomFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let sourceTokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private lazy var customFeeTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: feeTokenItem.decimalCount)
    private lazy var gasLimitTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: 0)
    private lazy var gasPriceTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.gweiDigits)
    private lazy var maxFeePerGasTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.gweiDigits)
    private lazy var priorityFeeTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.gweiDigits)
    private lazy var nonceTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: 0)

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

    private var nonce: Int? { nonceTextField.value?.intValue() }

    private let _customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
    private var customFeeBeforeEditing: Fee?
    private var customMaxFeePerGasBeforeEditing: BigUInt?
    private var customPriorityFeeBeforeEditing: BigUInt?
    private var customMaxLimitBeforeEditing: BigUInt?
    private var customGasPriceBeforeEditing: BigUInt?
    private var customNonceBeforeEditing: Int?

    private var zeroFee: Fee {
        return Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    private var cachedCustomFee: Fee?
    private var bag: Set<AnyCancellable> = []

    init(sourceTokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.sourceTokenItem = sourceTokenItem
        self.feeTokenItem = feeTokenItem

        bind()
    }

    private func bind() {
        _customFee
            .compactMap { $0 }
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.updateView(fee: customFee)
                service.output?.customFeeDidChanged(customFee)
            }
            .store(in: &bag)

        customFeeTextField.valuePublisher
            .withWeakCaptureOf(self)
            .sink(receiveValue: { $0._customFee.send($0.calculateFee(for: $1)) })
            .store(in: &bag)

        Publishers.MergeMany(
            gasLimitTextField.valuePublisher.removeDuplicates(),
            gasPriceTextField.valuePublisher.removeDuplicates(),
            maxFeePerGasTextField.valuePublisher.removeDuplicates(),
            priorityFeeTextField.valuePublisher.removeDuplicates(),
            nonceTextField.valuePublisher.removeDuplicates(),
        )
        .withWeakCaptureOf(self)
        .sink(receiveValue: { $0.0._customFee.send($0.0.recalculateFee()) })
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
            guard let gasLimit = gasLimit,
                  let maxFeePerGas = maxFeePerGas,
                  let priorityFee = priorityFee else {
                return zeroFee
            }

            parameters = EthereumEIP1559FeeParameters(
                gasLimit: gasLimit,
                maxFeePerGas: maxFeePerGas,
                priorityFee: priorityFee,
                nonce: nonce
            )
        } else {
            guard let gasLimit = gasLimit, let gasPrice = gasPrice else {
                return zeroFee
            }

            parameters = EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice, nonce: nonce)
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
                nonce: nonce
            )
        } else {
            let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
            parameters = EthereumLegacyFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice, nonce: nonce)
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
            maxFeePerGasTextField.update(value: eip1559Parameters.maxFeePerGas.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
            priorityFeeTextField.update(value: eip1559Parameters.priorityFee.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
            nonceTextField.update(value: eip1559Parameters.nonce.map { Decimal($0) })
        case .legacy(let legacyParameters):
            gasLimitTextField.update(value: legacyParameters.gasLimit.decimal)
            gasPriceTextField.update(value: legacyParameters.gasPrice.decimal?.shiftOrder(magnitude: -Constants.gweiDigits))
            nonceTextField.update(value: legacyParameters.nonce.map { Decimal($0) })
        }
    }
}

// MARK: - CustomFeeProvider

extension EVMCustomFeeService: CustomFeeProvider {
    var customFee: TokenFee {
        TokenFee(option: .custom, tokenItem: feeTokenItem, value: _customFee.value.map { .success($0) } ?? .loading)
    }

    var customFeePublisher: AnyPublisher<TokenFee, Never> {
        _customFee
            .withWeakCaptureOf(self)
            .map { TokenFee(option: .custom, tokenItem: $0.feeTokenItem, value: $1.map { .success($0) } ?? .loading) }
            .eraseToAnyPublisher()
    }

    func initialSetupCustomFee(_ fee: BSDKFee) {
        assert(_customFee.value == nil, "Duplicate initial setup")

        _customFee.send(fee)
        updateView(fee: fee)
    }
}

// MARK: - FeeSelectorCustomFeeFieldsBuilder

extension EVMCustomFeeService: FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool {
        _customFee.value != zeroFee
    }

    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> {
        _customFee
            .withWeakCaptureOf(self)
            .map { $0.zeroFee != $1 }
            .eraseToAnyPublisher()
    }

    func captureCustomFeeFieldsValue() {
        cachedCustomFee = _customFee.value
    }

    func resetCustomFeeFieldsValue() {
        if let cachedCustomFee {
            _customFee.send(cachedCustomFee)
            updateView(fee: cachedCustomFee)
        }
    }
}

// MARK: - FeeSelectorCustomFeeFieldsBuilder

extension EVMCustomFeeService: FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        let customFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendMaxFee,
            tooltip: Localization.sendCustomAmountFeeFooter,
            suffix: feeTokenItem.currencySymbol,
            isEditable: true,
            textFieldViewModel: customFeeTextField,
            amountAlternativePublisher: _customFee
                .compactMap { $0 }
                .withWeakCaptureOf(self)
                .map { $0.formatToFiat(value: $1.amount.value) }
                .eraseToAnyPublisher(),
            onFocusChanged: { [weak self] focused in
                self?.onCustomFeeChanged(focused)
            },
            accessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeTotalAmountField,
            alternativeAmountAccessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeMaxFeeFiatValue
        )

        let gasLimitRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendGasLimit,
            tooltip: Localization.sendGasLimitFooter,
            suffix: nil,
            isEditable: true,
            textFieldViewModel: gasLimitTextField,
            amountAlternativePublisher: AnyPublisher.just(output: nil)
        ) { [weak self] focused in
            self?.onGasLimitChanged(focused)
        }

        let nonceRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendNonce,
            tooltip: Localization.sendNonceFooter,
            suffix: nil,
            isEditable: true,
            textFieldViewModel: nonceTextField,
            amountAlternativePublisher: AnyPublisher.just(output: nil),
            onFocusChanged: { [weak self] focused in
                self?.onNonceChanged(focused)
            },
            accessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeNonceField
        )

        if feeTokenItem.blockchain.supportsEIP1559 {
            let maxFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
                title: Localization.sendCustomEvmMaxFee,
                tooltip: Localization.sendCustomEvmMaxFeeFooter,
                suffix: Constants.gweiSuffix,
                isEditable: true,
                textFieldViewModel: maxFeePerGasTextField,
                amountAlternativePublisher: AnyPublisher.just(output: nil)
            ) { [weak self] focused in
                self?.onMaxFeePerGasChanged(focused)
            }

            let priorityFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
                title: Localization.sendCustomEvmPriorityFee,
                tooltip: Localization.sendCustomEvmPriorityFeeFooter,
                suffix: Constants.gweiSuffix,
                isEditable: true,
                textFieldViewModel: priorityFeeTextField,
                amountAlternativePublisher: AnyPublisher.just(output: nil)
            ) { [weak self] focused in
                self?.onPriorityFeeChanged(focused)
            }

            return [
                customFeeRowViewModel,
                maxFeeRowViewModel,
                priorityFeeRowViewModel,
                gasLimitRowViewModel,
                nonceRowViewModel,
            ]
        } else {
            let gasPriceRowViewModel = FeeSelectorCustomFeeRowViewModel(
                title: Localization.sendGasPrice,
                tooltip: Localization.sendGasPriceFooter,
                suffix: Constants.gweiSuffix,
                isEditable: true,
                textFieldViewModel: gasPriceTextField,
                amountAlternativePublisher: AnyPublisher.just(output: nil)
            ) { [weak self] focused in
                self?.onGasPriceChanged(focused)
            }

            return [
                customFeeRowViewModel,
                gasPriceRowViewModel,
                gasLimitRowViewModel,
                nonceRowViewModel,
            ]
        }
    }
}

// MARK: - Analytics

private extension EVMCustomFeeService {
    private func onCustomFeeChanged(_ focused: Bool) {
        if focused {
            customFeeBeforeEditing = _customFee.value
        } else {
            if _customFee.value != customFeeBeforeEditing {
                Analytics.log(.sendCustomFeeInserted)
            }
        }
    }

    private func onMaxFeePerGasChanged(_ focused: Bool) {
        if focused {
            customMaxFeePerGasBeforeEditing = maxFeePerGas
        } else {
            if maxFeePerGas != customMaxFeePerGasBeforeEditing {
                Analytics.log(.sendMaxFeeInserted)
            }

            customMaxFeePerGasBeforeEditing = nil
        }
    }

    private func onPriorityFeeChanged(_ focused: Bool) {
        if focused {
            customPriorityFeeBeforeEditing = priorityFee
        } else {
            if priorityFee != customPriorityFeeBeforeEditing {
                Analytics.log(.sendPriorityFeeInserted)
            }

            customPriorityFeeBeforeEditing = nil
        }
    }

    private func onGasLimitChanged(_ focused: Bool) {
        if focused {
            customMaxLimitBeforeEditing = gasLimit
        } else {
            if gasLimit != customMaxLimitBeforeEditing {
                Analytics.log(.sendGasLimitInserted)
            }

            customMaxLimitBeforeEditing = nil
        }
    }

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

    private func onNonceChanged(_ focused: Bool) {
        if focused {
            customNonceBeforeEditing = nonce
        } else {
            let customNonceAfterEditing = nonce
            if customNonceAfterEditing != customNonceBeforeEditing {
                let params: [Analytics.ParameterKey: String] = [
                    .token: sourceTokenItem.currencySymbol,
                    .blockchain: sourceTokenItem.blockchain.currencySymbol,
                ]

                Analytics.log(event: .sendNonceInserted, params: params)
            }

            customNonceBeforeEditing = nil
        }
    }
}

// MARK: - Private extensions

private extension EVMCustomFeeService {
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
