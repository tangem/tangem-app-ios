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
    private let gasLimit = CurrentValueSubject<BigUInt?, Never>(nil)
    private let baseFee = CurrentValueSubject<BigUInt?, Never>(nil)
    private let priorityFee = CurrentValueSubject<BigUInt?, Never>(nil)

    private let blockchain: Blockchain
    private let feeTokenItem: TokenItem

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?
    private var bag: Set<AnyCancellable> = []
    private var customGasPriceBeforeEditing: BigUInt?

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        blockchain: Blockchain,
        feeTokenItem: TokenItem
    ) {
        self.input = input
        self.output = output
        self.blockchain = blockchain
        self.feeTokenItem = feeTokenItem

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
                    return
                }

                updateProperties(fee: fee)
                output?.setCustomFee(fee)
            }
            .store(in: &bag)
    }

    private func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        gasLimit.send(value)
        output?.setCustomFee(recalculateFee())
    }

    private func didChangeCustomFeeBaseFee(_ value: BigUInt?) {
        baseFee.send(value)
        output?.setCustomFee(recalculateFee())
    }

    private func didChangeCustomFeePriorityFee(_ value: BigUInt?) {
        priorityFee.send(value)
        output?.setCustomFee(recalculateFee())
    }

    private func recalculateFee() -> Fee? {
        guard let gasLimit = gasLimit.value, let baseFee = baseFee.value, let priorityFee = priorityFee.value else {
            return nil
        }

        let parameters = EthereumEIP1559FeeParameters(gasLimit: gasLimit, baseFee: baseFee, priorityFee: priorityFee)
        let fee = parameters.caclulateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func recalculateFee(from value: Decimal?) -> Fee? {
        let feeDecimalValue = feeTokenItem.decimalValue

        guard
            let value,
            let currentGasLimit = gasLimit.value,
            let currentPriorityFee = priorityFee.value,
            let enteredFeeInSmallestDenomination = BigUInt(decimal: (value * feeDecimalValue).rounded(roundingMode: .down))
        else {
            return nil
        }

        let baseFee = (enteredFeeInSmallestDenomination / currentGasLimit) - currentPriorityFee
        let parameters = EthereumEIP1559FeeParameters(gasLimit: currentGasLimit, baseFee: baseFee, priorityFee: currentPriorityFee)
        let fee = parameters.caclulateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }
}

extension CustomEvmFeeService: CustomFeeService {
    var customFeeDescription: String? {
        Localization.sendEvmCustomFeeFooter
    }

    var readOnlyCustomFee: Bool {
        false
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let gweiFractionDigits = 9
        let baseFeeGweiPublisher = baseFee
            .map { $0?.decimal?.shiftOrder(magnitude: -gweiFractionDigits) }
            .eraseToAnyPublisher()

        let baseFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendBaseFee,
            amountPublisher: baseFeeGweiPublisher,
            fieldSuffix: "GWEI",
            fractionDigits: gweiFractionDigits,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendBaseFeeFooter
        ) { [weak self] gweiValue in
            let weiValue = gweiValue?.shiftOrder(magnitude: gweiFractionDigits)
            self?.didChangeCustomFeeBaseFee(weiValue?.bigUIntValue)
        } onFocusChanged: { [weak self] focused in
            self?.onGasPriceFocusChanged(focused)
        }

        let priorityFeeGweiPublisher = priorityFee
            .map { $0?.decimal?.shiftOrder(magnitude: -gweiFractionDigits) }
            .eraseToAnyPublisher()

        let priorityFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendPriorityFee,
            amountPublisher: priorityFeeGweiPublisher,
            fieldSuffix: "GWEI",
            fractionDigits: gweiFractionDigits,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendPriorityFeeFooter
        ) { [weak self] gweiValue in
            let weiValue = gweiValue?.shiftOrder(magnitude: gweiFractionDigits)
            self?.didChangeCustomFeePriorityFee(weiValue?.bigUIntValue)
        } onFocusChanged: { [weak self] focused in
            self?.onGasPriceFocusChanged(focused)
        }

        let gasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: gasLimit.map { $0?.decimal }.eraseToAnyPublisher(),
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            self?.didChangeCustomFeeGasLimit($0?.bigUIntValue)
        }

        return [baseFeeModel, priorityFeeModel, gasLimitModel]
    }

    func setCustomFee(value: Decimal?) {
        let fee = recalculateFee(from: value)

        output?.setCustomFee(fee)
        updateProperties(fee: fee)
    }

    private func updateProperties(fee: Fee?) {
        guard let ethereumFeeParameters = fee?.parameters as? EthereumEIP1559FeeParameters else {
            return
        }

        gasLimit.send(ethereumFeeParameters.gasLimit)
        baseFee.send(ethereumFeeParameters.baseFee)
        priorityFee.send(ethereumFeeParameters.priorityFee)
    }

    private func onGasPriceFocusChanged(_ focused: Bool) {
        if focused {
            customGasPriceBeforeEditing = baseFee.value
        } else {
            let customGasPriceAfterEditing = baseFee.value
            if customGasPriceAfterEditing != customGasPriceBeforeEditing {
                Analytics.log(.sendGasPriceInserted)
            }

            customGasPriceBeforeEditing = nil
        }
    }
}

// MARK: - private extensions

private extension Decimal {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: self)
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
