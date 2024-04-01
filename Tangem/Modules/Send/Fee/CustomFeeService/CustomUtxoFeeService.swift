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
    weak var input: SendModel?

    var customFeePublisher: AnyPublisher<Fee?, Never> {
        _customFee.eraseToAnyPublisher()
    }

    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)
    private let _customFeeSatoshiPerByte = CurrentValueSubject<Int?, Never>(nil)

    private var didSetCustomFee = false

//    init(input: SendModel) {
    init() {
//        self.input = input
    }

    func setInput(_ input: SendModel) {
        self.input = input
    }

    func setFee(_ fee: Fee) {
        guard let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters else {
            assertionFailure("WHY?")
            return
        }

        _customFee.send(fee)
        _customFeeSatoshiPerByte.send(bitcoinFeeParameters.rate)
    }

    func didChangeCustomFee(_ value: Fee?) {
        didSetCustomFee = true
        _customFee.send(value)
//        fee.send(value)

        if let bitcoinParams = value?.parameters as? BitcoinFeeParameters {
            _customFeeSatoshiPerByte.send(bitcoinParams.rate)
        }
    }

    func models() -> [SendCustomFeeInputFieldModel] {
        guard let input else { return [] }

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
            let intValue: Int?
            if let decimalValue {
                intValue = (decimalValue as NSDecimalNumber).intValue
            } else {
                intValue = nil
            }

            self?.didChangeCustomSatoshiPerByte(intValue)
        }

        return [customFeeSatoshiPerByteModel]
    }

    func didChangeCustomSatoshiPerByte(_ value: Int?) {
        _customFeeSatoshiPerByte.send(value)
        recalculateCustomFee()
    }

    private func recalculateCustomFee() {
        if let utxoTransactionFeeCalculator = input?.utxoTransactionFeeCalculator {
            let newFee: Fee?
            if let satoshiPerByte = _customFeeSatoshiPerByte.value,
               let amount = input?.validatedAmountValue,
               let destination = input?.destinationText {
                newFee = utxoTransactionFeeCalculator.calculateFee(satoshiPerByte: satoshiPerByte, amount: amount, destination: destination)
            } else {
                newFee = nil
            }
            print("ZZZ satoshi per byte", _customFeeSatoshiPerByte.value)
            print("ZZZ recalc new fee", newFee)

            didSetCustomFee = true
            _customFee.send(newFee)
//            fee.send(newFee)
        }
    }
}

extension CustomUtxoFeeService: CustomFeeService {}

// typealias CustomFeeService = CustomUtxoFeeService
