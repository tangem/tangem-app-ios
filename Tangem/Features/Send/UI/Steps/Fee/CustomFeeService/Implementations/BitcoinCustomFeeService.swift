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

    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
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
            service.customFee.send(fee)
        }
        .store(in: &bag)

        customFee
            .compactMap { $0 }
            // Skip the initial value
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.customFeeTextField.update(value: customFee.amount.value)
                service.output?.customFeeDidChanged(customFee)
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

extension BitcoinCustomFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        self.output = output
    }

    func initialSetupCustomFee(_ fee: BlockchainSdk.Fee) {
        assert(customFee.value == nil, "Duplicate initial setup")

        customFee.send(fee)
        updateView(fee: fee)
    }
}

// MARK: - FeeSelectorCustomFeeFieldsBuilder

extension BitcoinCustomFeeService: FeeSelectorCustomFeeFieldsBuilder {
    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> {
        customFee
            .withWeakCaptureOf(self)
            .map { $0.zeroFee != $1 }
            .eraseToAnyPublisher()
    }

    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        let customFeeRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendMaxFee,
            tooltip: Localization.sendBitcoinCustomFeeFooter,
            suffix: feeTokenItem.currencySymbol,
            isEditable: false,
            textFieldViewModel: customFeeTextField,
            amountAlternativePublisher: customFee
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

    func captureCustomFeeFieldsValue() {
        cachedCustomFee = customFee.value
    }

    func resetCustomFeeFieldsValue() {
        if let cachedCustomFee {
            customFee.send(cachedCustomFee)
            updateView(fee: cachedCustomFee)
        }
    }
}
