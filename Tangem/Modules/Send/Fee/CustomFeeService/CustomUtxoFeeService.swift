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
    private let satoshiPerByte = CurrentValueSubject<Int?, Never>(nil)
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
                    input.customFee == nil
                else {
                    print("ZZZ updating initial fee", "NO")
                    return
                }

                print("ZZZ updating initial fee", fee)
                if let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters {
                    satoshiPerByte.send(bitcoinFeeParameters.rate)
                }
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            satoshiPerByte,
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
        print("ZZZ satoshi per byte", self.satoshiPerByte.value)
        print("ZZZ recalc new fee", newFee)

        output?.setCustomFee(newFee)
    }
}

extension CustomUtxoFeeService: CustomFeeService {
    var customFeeDescription: String? {
        nil
    }

    var readOnlyCustomFee: Bool {
        true
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let satoshiPerBytePublisher = satoshiPerByte
            .map { intValue -> Decimal? in
                if let intValue {
                    Decimal(intValue)
                } else {
                    nil
                }
            }
            .eraseToAnyPublisher()

        let customFeeSatoshiPerByteModel = SendCustomFeeInputFieldModel(
            title: Localization.sendSatoshiPerByteTitle,
            amountPublisher: satoshiPerBytePublisher,
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: nil
        ) { [weak self] decimalValue in
            let intValue = (decimalValue as NSDecimalNumber?)?.intValue
            self?.satoshiPerByte.send(intValue)
        }

        return [customFeeSatoshiPerByteModel]
    }

    func setCustomFee(value: Decimal?) {
        print("zzz Aaaaa didChangeCustomFee utxo????????????????????????????")
    }
}
