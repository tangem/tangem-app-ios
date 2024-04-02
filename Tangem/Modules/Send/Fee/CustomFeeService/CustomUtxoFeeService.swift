//
//  CustomUtxoFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CustomUtxoFeeService {
    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)
    private let _customFeeSatoshiPerByte = CurrentValueSubject<Int?, Never>(nil)

    private let utxoTransactionFeeCalculator: UTXOTransactionFeeCalculator

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?

    private var bag: Set<AnyCancellable> = []

    init(input: CustomFeeServiceInput, output: CustomFeeServiceOutput, utxoTransactionFeeCalculator: UTXOTransactionFeeCalculator) {
        self.input = input
        self.output = output
        self.utxoTransactionFeeCalculator = utxoTransactionFeeCalculator

        bind()
    }

    private func bind() {
        guard let input else {
            assertionFailure("WHY")
            return
        }

        input
            .feeValuePublisher
            .sink { [weak self] fee in
                guard
                    let self,
                    let fee,
                    _customFee.value == nil
                else {
                    print("ZZZ updating initial fee", "NO")
                    return
                }

                print("ZZZ updating initial fee", fee)
                if let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters {
                    _customFeeSatoshiPerByte.send(bitcoinFeeParameters.rate)
                    _customFee.send(fee)
                }
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            _customFeeSatoshiPerByte,
            input.amountPublisher,
            input.destinationPublisher.map(\.?.value)
        )
        .sink { [weak self] satoshiPerByte, amount, destination in
            print("ZZZ recalculating", satoshiPerByte, amount, destination)
            self?.recalculateCustomFee(
                satoshiPerByte: satoshiPerByte,
                amount: amount,
                destination: destination
            )
        }
        .store(in: &bag)
    }

    private func recalculateCustomFee(satoshiPerByte: Int?, amount: Amount?, destination: String?) {
        let newFee: Fee?
        if let satoshiPerByte,
           let amount,
           let destination {
            newFee = utxoTransactionFeeCalculator.calculateFee(satoshiPerByte: satoshiPerByte, amount: amount, destination: destination)
        } else {
            newFee = nil
        }
        print("ZZZ satoshi per byte", _customFeeSatoshiPerByte.value)
        print("ZZZ recalc new fee", newFee)

        output?.setCustomFee(newFee)
    }
}

extension CustomUtxoFeeService: CustomFeeService {
    var customFeeDescription: String? {
        nil
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let satoshiPerBytePublisher = _customFeeSatoshiPerByte
            .map { intValue -> Decimal? in
                if let intValue {
                    Decimal(intValue)
                } else {
                    nil
                }
            }
            .eraseToAnyPublisher()

        let customFeeSatoshiPerByteModel = SendCustomFeeInputFieldModel(
            title: "Satoshi per byte",
            amountPublisher: satoshiPerBytePublisher,
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: nil
        ) { [weak self] decimalValue in
            let intValue = (decimalValue as NSDecimalNumber?)?.intValue
            self?._customFeeSatoshiPerByte.send(intValue)
        }

        return [customFeeSatoshiPerByteModel]
    }

    func setCustomFee(enteredFee: Decimal?) {
        print("zzz Aaaaa didChangeCustomFee utxo????????????????????????????")
    }
}
