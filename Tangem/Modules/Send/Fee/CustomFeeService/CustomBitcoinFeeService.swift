//
//  CustomBitcoinFeeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CustomBitcoinFeeService {
    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?

    private let feeTokenItem: TokenItem
    private let bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator

    private let satoshiPerByte = CurrentValueSubject<Int?, Never>(nil)
    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
    private let customFeeInFiat: CurrentValueSubject<String?, Never> = .init(.none)
    private var customFeeBeforeEditing: Fee?
    private var bag: Set<AnyCancellable> = []

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        feeTokenItem: TokenItem,
        bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator
    ) {
        self.input = input
        self.output = output
        self.feeTokenItem = feeTokenItem
        self.bitcoinTransactionFeeCalculator = bitcoinTransactionFeeCalculator

        bind(input: input)
    }

    private func bind(input: CustomFeeServiceInput) {
        Publishers.CombineLatest3(
            satoshiPerByte,
            input.cryptoAmountPublisher,
            input.destinationAddressPublisher
        )
        .sink { [weak self] satoshiPerByte, amount, destination in
            self?.recalculateCustomFee(
                satoshiPerByte: satoshiPerByte,
                amount: amount,
                destination: destination
            )
        }
        .store(in: &bag)

        customFee
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.customFeeDidChanged(fee: customFee)
            }
            .store(in: &bag)
    }

    private func customFeeDidChanged(fee: Fee?) {
        let fortmatted = fortmatToFiat(value: fee?.amount.value)
        customFeeInFiat.send(fortmatted)

        output?.customFeeDidChanged(fee)
    }

    private func fortmatToFiat(value: Decimal?) -> String? {
        guard let value,
              let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }

    private func recalculateCustomFee(satoshiPerByte: Int?, amount: Amount, destination: String) {
        guard let satoshiPerByte else {
            output?.customFeeDidChanged(.none)
            return
        }

        let newFee = bitcoinTransactionFeeCalculator.calculateFee(
            satoshiPerByte: satoshiPerByte,
            amount: amount,
            destination: destination
        )

        output?.customFeeDidChanged(newFee)
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
            let intValue: Int?
            if let roundedValue = decimalValue?.rounded() {
                intValue = (roundedValue as NSDecimalNumber).intValue
            } else {
                intValue = nil
            }
            self?.satoshiPerByte.send(intValue)
        }

        return [customFeeModel, customFeeSatoshiPerByteModel]
    }
}
