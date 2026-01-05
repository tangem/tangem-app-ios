//
//  BitcoinCustomFeeService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import BlockchainSdk
import TangemFoundation
import TangemAccessibilityIdentifiers

class BitcoinCustomFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator

    private lazy var customFeeTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: feeTokenItem.decimalCount)
    private lazy var satoshiPerByteTextField = DecimalNumberTextFieldViewModel(maximumFractionDigits: 0)

    private let _customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
    private var cachedCustomFee: Fee?
    private var bag: Set<AnyCancellable> = []

    private var zeroFee: Fee {
        return Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    init(
        input: CustomFeeServiceInput,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator,
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.bitcoinTransactionFeeCalculator = bitcoinTransactionFeeCalculator

        bind(input: input)
    }

    private func bind(input: CustomFeeServiceInput) {
        Publishers.CombineLatest3(
            satoshiPerByteTextField.valuePublisher.map { $0?.intValue() },
            input.cryptoAmountPublisher,
            input.destinationAddressPublisher
        )
        .withWeakCaptureOf(self)
        .asyncMap { service, args in
            let (satoshiPerByte, amount, destination) = args

            return await service.recalculateCustomFee(
                satoshiPerByte: satoshiPerByte,
                amount: amount,
                destination: destination
            )
        }
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { service, fee in
            service._customFee.send(fee)
        }
        .store(in: &bag)

        _customFee
            .compactMap { $0 }
            // Skip the initial value
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { service, _customFee in
                service.customFeeTextField.update(value: _customFee.amount.value)
                service.output?.customFeeDidChanged(_customFee)
            }
            .store(in: &bag)
    }

    private func formatToFiat(value: Decimal?) -> String? {
        guard let value, let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }

    private func recalculateCustomFee(satoshiPerByte: Int?, amount: Decimal, destination: String) async -> Fee {
        guard let satoshiPerByte else {
            return zeroFee
        }

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        do {
            let newFee = try await bitcoinTransactionFeeCalculator.calculateFee(
                satoshiPerByte: satoshiPerByte,
                amount: amount,
                destination: destination
            )

            return newFee
        } catch {
            AppLogger.error(error: error)
            return zeroFee
        }
    }

    func updateView(fee: BSDKFee) {
        guard let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters else {
            return
        }

        customFeeTextField.update(value: fee.amount.value)
        satoshiPerByteTextField.update(value: Decimal(bitcoinFeeParameters.rate))
    }
}

// MARK: - CustomFeeService

extension BitcoinCustomFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        self.output = output
    }
}

// MARK: - FeeSelectorCustomFeeProvider

extension BitcoinCustomFeeService: FeeSelectorCustomFeeProvider {
    var customFee: SendFee {
        SendFee(option: .custom, value: _customFee.value.map { .success($0) } ?? .loading)
    }

    var customFeePublisher: AnyPublisher<SendFee, Never> {
        _customFee
            .map { SendFee(option: .custom, value: $0.map { .success($0) } ?? .loading) }
            .eraseToAnyPublisher()
    }

    func initialSetupCustomFee(_ fee: BlockchainSdk.Fee) {
        assert(_customFee.value == nil, "Duplicate initial setup")

        _customFee.send(fee)
        updateView(fee: fee)
    }
}

// MARK: - FeeSelectorCustomFeeAvailabilityProvider

extension BitcoinCustomFeeService: FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { _customFee.value != zeroFee }

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

extension BitcoinCustomFeeService: FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        let customFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendMaxFee,
            tooltip: Localization.sendBitcoinCustomFeeFooter,
            suffix: feeTokenItem.currencySymbol,
            isEditable: false,
            textFieldViewModel: customFeeTextField,
            amountAlternativePublisher: _customFee
                .compactMap { $0 }
                .withWeakCaptureOf(self)
                .map { $0.formatToFiat(value: $1.amount.value) }
                .eraseToAnyPublisher(),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeMaxFeeField,
            alternativeAmountAccessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeMaxFeeFiatValue
        )

        let satoshiPerByteRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendSatoshiPerByteTitle,
            tooltip: Localization.sendSatoshiPerByteText,
            suffix: nil,
            isEditable: true,
            textFieldViewModel: satoshiPerByteTextField,
            amountAlternativePublisher: AnyPublisher.just(output: nil),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.customFeeSatoshiPerByteField
        )

        return [customFeeRowViewModel, satoshiPerByteRowViewModel]
    }
}
