//
//  CustomEvmFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import BigInt

class CustomEvmFeeService {
    var customFeePublisher: AnyPublisher<Fee?, Never> {
        _customFee.eraseToAnyPublisher()
    }

    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)

    private let _customFeeGasPrice = CurrentValueSubject<BigUInt?, Never>(nil)
    private let _customFeeGasLimit = CurrentValueSubject<BigUInt?, Never>(nil)
    private var didSetCustomFee = false

    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func didChangeCustomFeeGasPrice(_ value: BigUInt?) {
        _customFeeGasPrice.send(value)
        recalculateCustomFee()
    }

    func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        _customFeeGasLimit.send(value)
        recalculateCustomFee()
    }

    private func recalculateCustomFee() {
        let newFee: Fee?
        if let gasPrice = _customFeeGasPrice.value,
           let gasLimit = _customFeeGasLimit.value,
           let gasInWei = (gasPrice * gasLimit).decimal {
            let blockchain = blockchain
            let validatedAmount = Amount(with: blockchain, value: gasInWei / blockchain.decimalValue)
            newFee = Fee(validatedAmount, parameters: EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice))
        } else {
            newFee = nil
        }

        didSetCustomFee = true
        _customFee.send(newFee)
//            fee.send(newFee)
//        }
    }
}

extension CustomEvmFeeService: CustomFeeService {
    func setInput(_ input: SendModel) {}

    func setFee(_ fee: BlockchainSdk.Fee?) {
        _customFee.send(fee)
        if let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters {
            _customFeeGasPrice.send(ethereumFeeParameters.gasPrice)
            _customFeeGasLimit.send(ethereumFeeParameters.gasLimit)
        }
    }

    func didChangeCustomFee(enteredFee: Decimal?, input: SendFeeViewModelInput, walletInfo: SendWalletInfo) {
//        if let ethereumParams = value?.parameters as? EthereumFeeParameters {
//            _customFeeGasLimit.send(ethereumParams.gasLimit)
//            _customFeeGasPrice.send(ethereumParams.gasPrice)
//        }

        let fee = recalculateFee(enteredFee: enteredFee, input: input, walletInfo: walletInfo)
//        _customFee.send(fee)
//
//        if let ethereumParams = fee?.parameters as? EthereumFeeParameters {
//            _customFeeGasLimit.send(ethereumParams.gasLimit)
//            _customFeeGasPrice.send(ethereumParams.gasPrice)
//        }

        setFee(fee)
    }

    func models() -> [SendCustomFeeInputFieldModel] {
        let gasPriceFractionDigits = 9
        let gasPriceGweiPublisher =
            _customFeeGasPrice
                .eraseToAnyPublisher()
//        input
//            .customGasPricePublisher
                .decimalPublisher
                .map { weiValue -> Decimal? in
                    let gweiValue = weiValue?.shiftOrder(magnitude: -gasPriceFractionDigits)
                    return gweiValue
                }
                .eraseToAnyPublisher()

        let customFeeGasPriceModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasPrice,
            amountPublisher: gasPriceGweiPublisher,
            fieldSuffix: "GWEI",
            fractionDigits: gasPriceFractionDigits,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasPriceFooter
        ) { [weak self] gweiValue in
            guard let self else { return }

            let weiValue = gweiValue?.shiftOrder(magnitude: gasPriceFractionDigits)
            didChangeCustomFeeGasPrice(weiValue?.bigUIntValue)
        }

        let customFeeGasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: _customFeeGasLimit.eraseToAnyPublisher().decimalPublisher,
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            guard let self else { return }
            didChangeCustomFeeGasLimit($0?.bigUIntValue)
        }

//        customFeeTitle = Localization.sendMaxFee
//        customFeeFooter = Localization.sendMaxFeeFooter

        //
        return [
            customFeeGasPriceModel,
            customFeeGasLimitModel,
        ]
    }

    func recalculateFee(enteredFee: Decimal?, input: SendFeeViewModelInput, walletInfo: SendWalletInfo) -> Fee? {
//        let sendModel = input as! SendModel
//        if sendModel.blockchainNetwork.blockchain.isEvm {
        let feeDecimalValue = Decimal(pow(10, Double(walletInfo.feeFractionDigits)))

        guard
            let enteredFee,
            let currentGasLimit = _customFeeGasLimit.value, // input.customGasLimit,
            let enteredFeeInSmallestDenomination = BigUInt(decimal: (enteredFee * feeDecimalValue).rounded(roundingMode: .down))
        else {
            return nil
        }

        let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
        guard
            let recalculatedFeeInSmallestDenomination = (gasPrice * currentGasLimit).decimal
        else {
            return nil
        }

        let recalculatedFee = recalculatedFeeInSmallestDenomination / feeDecimalValue
        let feeAmount = Amount(with: walletInfo.blockchain, type: walletInfo.feeAmountType, value: recalculatedFee)
        let parameters = EthereumFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice)
        return Fee(feeAmount, parameters: parameters)
//        } else {
//            return nil
//        }
    }
}

// MARK: - private extensions

private extension Decimal {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: self)
    }
}

private extension AnyPublisher where Output == Fee?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.amount.value }.eraseToAnyPublisher()
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.decimal }.eraseToAnyPublisher()
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
