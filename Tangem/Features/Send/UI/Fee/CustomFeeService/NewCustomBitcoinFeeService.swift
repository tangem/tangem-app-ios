//
//  NewCustomBitcoinFeeService.swift
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

class NewCustomBitcoinFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator

    private lazy var customFeeTextField = DecimalNumberTextField.ViewModel(maximumFractionDigits: feeTokenItem.decimalCount)
    private lazy var satoshiPerByteTextField = DecimalNumberTextField.ViewModel(maximumFractionDigits: 0)

    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
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
}

extension NewCustomBitcoinFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        self.output = output
    }

    func initialSetupCustomFee(_ fee: BlockchainSdk.Fee) {
        assert(customFee.value == nil, "Duplicate initial setup")

        guard let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters else {
            return
        }

        customFee.send(fee)
        customFeeTextField.update(value: fee.amount.value)
        satoshiPerByteTextField.update(value: Decimal(bitcoinFeeParameters.rate))
    }

    func selectorCustomFeeRowViewModels() -> [FeeSelectorCustomFeeRowViewModel] {
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
                .eraseToAnyPublisher()
        )

        let satoshiPerByteRowViewModel = FeeSelectorCustomFeeRowViewModel(
            title: Localization.sendSatoshiPerByteTitle,
            tooltip: Localization.sendSatoshiPerByteText,
            suffix: nil,
            isEditable: true,
            textFieldViewModel: satoshiPerByteTextField,
            amountAlternativePublisher: AnyPublisher.just(output: nil)
        )

        return [customFeeRowViewModel, satoshiPerByteRowViewModel]
    }
}
