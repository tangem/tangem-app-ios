//
//  KaspaCustomFeeService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import Combine

class KaspaCustomFeeService {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private lazy var customFeeTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: feeTokenItem.decimalCount)

    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)

    private var cachedCustomFee: Fee?
    private var initialCustomFee: Fee
    private var customFeeEnricher: KaspaKRC20FeeParametersEnricher?
    private var bag: Set<AnyCancellable> = []

    private var zeroFee: Fee {
        Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: .zero))
    }

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        let zeroAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: .zero)
        initialCustomFee = Fee(zeroAmount)
    }

    private func bind(output: CustomFeeServiceOutput) {
        _customFee
            .compactMap { $0 }
            .dropFirst()
            .sink { [weak output] fee in
                output?.customFeeDidChanged(fee)
            }
            .store(in: &bag)

        customFeeTextField.valuePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.onFieldChange(decimalValue: $1) }
            .store(in: &bag)
    }

    private func formatToFiat(value: Decimal?) -> String? {
        guard let value,
              let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }

    private func onFieldChange(decimalValue: Decimal?) {
        guard let decimalValue, decimalValue > 0 else {
            _customFee.send(zeroFee)
            return
        }

        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: decimalValue)
        var fee = Fee(amount)

        if tokenItem.isToken, let customFeeEnricher {
            customFeeEnricher.enrichCustomFeeIfNeeded(&fee)
        }

        _customFee.send(fee)
    }

    private func onFocusChanged(isSelected: Bool) {
        guard
            !isSelected,
            tokenItem.isToken,
            let currentCustomFee = _customFee.value,
            currentCustomFee.amount < initialCustomFee.amount
        else {
            return
        }

        // Reset a value in the input
        customFeeTextField.update(value: initialCustomFee.amount.value)
        _customFee.send(initialCustomFee)
    }
}

// MARK: - CustomFeeService

extension KaspaCustomFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        bind(output: output)
    }
}

// MARK: - FeeSelectorCustomFeeProvider

extension KaspaCustomFeeService: FeeSelectorCustomFeeProvider {
    var customFee: TokenFee {
        TokenFee(option: .custom, tokenItem: feeTokenItem, value: _customFee.value.map { .success($0) } ?? .loading)
    }

    var customFeePublisher: AnyPublisher<TokenFee, Never> {
        _customFee
            .withWeakCaptureOf(self)
            .map { TokenFee(option: .custom, tokenItem: $0.feeTokenItem, value: $1.map { .success($0) } ?? .loading) }
            .eraseToAnyPublisher()
    }

    func initialSetupCustomFee(_ fee: Fee) {
        customFeeTextField.update(value: fee.amount.value)
        initialCustomFee = fee
        customFeeEnricher = KaspaKRC20FeeParametersEnricher(existingFeeParameters: fee.parameters)
    }
}

// MARK: - FeeSelectorCustomFeeAvailabilityProvider

extension KaspaCustomFeeService: FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { _customFee.value != initialCustomFee }

    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> {
        _customFee
            .withWeakCaptureOf(self)
            .map { $0.initialCustomFee != $1 }
            .eraseToAnyPublisher()
    }

    func captureCustomFeeFieldsValue() {
        cachedCustomFee = _customFee.value ?? initialCustomFee
    }

    func resetCustomFeeFieldsValue() {
        if let cachedCustomFee {
            _customFee.send(cachedCustomFee)
            customFeeTextField.update(value: cachedCustomFee.amount.value)
        }
    }
}

// MARK: - FeeSelectorCustomFeeFieldsBuilder

extension KaspaCustomFeeService: FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        return [
            FeeSelectorCustomFeeRowViewModel(
                title: Localization.sendMaxFee,
                tooltip: Localization.sendCustomAmountFeeFooter,
                suffix: feeTokenItem.currencySymbol,
                isEditable: true,
                textFieldViewModel: customFeeTextField,
                amountAlternativePublisher: _customFee
                    .compactMap { $0 }
                    .withWeakCaptureOf(self)
                    .map { $0.formatToFiat(value: $1.amount.value) }
                    .eraseToAnyPublisher()
            ) { [weak self] focused in
                self?.onFocusChanged(isSelected: focused)
            },
        ]
    }
}
