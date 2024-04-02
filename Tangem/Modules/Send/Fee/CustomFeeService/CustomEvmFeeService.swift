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
    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)

    private let _customFeeGasPrice = CurrentValueSubject<BigUInt?, Never>(nil)
    private let _customFeeGasLimit = CurrentValueSubject<BigUInt?, Never>(nil)

    private let blockchain: Blockchain

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?

    private var bag: Set<AnyCancellable> = []

    init(input: CustomFeeServiceInput, output: CustomFeeServiceOutput, blockchain: Blockchain) {
        self.input = input
        self.output = output
        self.blockchain = blockchain

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
                if let ethereumFeeParameters = fee.parameters as? EthereumFeeParameters {
                    _customFeeGasPrice.send(ethereumFeeParameters.gasPrice)
                    _customFeeGasLimit.send(ethereumFeeParameters.gasLimit)
                    _customFee.send(fee)
                    output?.setCustomFee(fee)
                }
            }
            .store(in: &bag)
    }

    private func didChangeCustomFeeGasPrice(_ value: BigUInt?) {
        _customFeeGasPrice.send(value)
        recalculateCustomFee(gasPrice: _customFeeGasPrice.value, gasLimit: _customFeeGasLimit.value)
    }

    private func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        _customFeeGasLimit.send(value)
        recalculateCustomFee(gasPrice: _customFeeGasPrice.value, gasLimit: _customFeeGasLimit.value)
    }

    private func recalculateCustomFee(gasPrice: BigUInt?, gasLimit: BigUInt?) {
        let newFee: Fee?
        if let gasPrice,
           let gasLimit,
           let gasInWei = (gasPrice * gasLimit).decimal {
            let blockchain = blockchain
            let validatedAmount = Amount(with: blockchain, value: gasInWei / blockchain.decimalValue)
            newFee = Fee(validatedAmount, parameters: EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice))
        } else {
            newFee = nil
        }

        output?.setCustomFee(newFee)
    }

    private func recalculateFee(enteredFee: Decimal?, input: SendFeeViewModelInput, walletInfo: SendWalletInfo) -> Fee? {
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
    }
}

extension CustomEvmFeeService: CustomFeeService {
    func models() -> [SendCustomFeeInputFieldModel] {
        let gasPriceFractionDigits = 9
        let gasPriceGweiPublisher = _customFeeGasPrice
            .eraseToAnyPublisher()
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

    func didChangeCustomFee(enteredFee: Decimal?, input: SendFeeViewModelInput, walletInfo: SendWalletInfo) {
        let fee = recalculateFee(enteredFee: enteredFee, input: input, walletInfo: walletInfo)

        _customFee.send(fee)
        output?.setCustomFee(fee)
        if let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters {
            _customFeeGasPrice.send(ethereumFeeParameters.gasPrice)
            _customFeeGasLimit.send(ethereumFeeParameters.gasLimit)
        }
    }
}

// MARK: - private extensions

private extension Decimal {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: self)
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
