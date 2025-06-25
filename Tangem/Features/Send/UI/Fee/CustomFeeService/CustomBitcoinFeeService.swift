//
//  CustomBitcoinFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import BlockchainSdk
import TangemFoundation

class CustomBitcoinFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator

    private let satoshiPerByte = CurrentValueSubject<Int?, Never>(nil)
    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
    private let customFeeInFiat: CurrentValueSubject<String?, Never> = .init(.none)
    private var customFeeBeforeEditing: Fee?
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
            satoshiPerByte.dropFirst(),
            input.cryptoAmountPublisher,
            input.destinationAddressPublisher
        )
        // Skip the initial values
        .dropFirst()
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
                service.customFeeDidChanged(fee: customFee)
            }
            .store(in: &bag)
    }

    private func customFeeDidChanged(fee: Fee) {
        let formatted = formatToFiat(value: fee.amount.value)
        customFeeInFiat.send(formatted)

        output?.customFeeDidChanged(fee)
    }

    private func formatToFiat(value: Decimal?) -> String? {
        guard let value,
              let currencyId = feeTokenItem.currencyId else {
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

    private func onCustomFeeChanged(_ focused: Bool) {
        if focused {
            customFeeBeforeEditing = customFee.value
        } else {
            if customFee.value != customFeeBeforeEditing {
                Analytics.log(.sendPriorityFeeInserted)
            }

            customFeeBeforeEditing = nil
        }
    }
}

extension CustomBitcoinFeeService: CustomFeeService {
    func setup(output: any CustomFeeServiceOutput) {
        self.output = output
    }

    func initialSetupCustomFee(_ fee: BlockchainSdk.Fee) {
        assert(customFee.value == nil, "Duplicate initial setup")

        guard let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters else {
            return
        }

        customFee.send(fee)
        satoshiPerByte.send(bitcoinFeeParameters.rate)
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let mainCustomAmount = customFee.map { $0?.amount.value }

        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: mainCustomAmount.eraseToAnyPublisher(),
            disabled: true,
            fieldSuffix: feeTokenItem.currencySymbol,
            fractionDigits: feeTokenItem.decimalCount,
            amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
            footer: Localization.sendBitcoinCustomFeeFooter,
            onFieldChange: nil
        ) { [weak self] focused in
            self?.onCustomFeeChanged(focused)
        }

        let satoshiPerBytePublisher = satoshiPerByte.map { $0.map { Decimal($0) } }

        let customFeeSatoshiPerByteModel = SendCustomFeeInputFieldModel(
            title: Localization.sendSatoshiPerByteTitle,
            amountPublisher: satoshiPerBytePublisher.eraseToAnyPublisher(),
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendSatoshiPerByteText
        ) { [weak self] decimalValue in
            let intValue = decimalValue?.intValue()
            self?.satoshiPerByte.send(intValue)
        }

        return [customFeeModel, customFeeSatoshiPerByteModel]
    }
}
