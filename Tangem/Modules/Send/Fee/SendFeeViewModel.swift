//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BigInt
import BlockchainSdk

protocol SendFeeViewModelInput {
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }

    var customFeePublisher: AnyPublisher<Fee?, Never> { get }
    var customGasPricePublisher: AnyPublisher<BigUInt?, Never> { get }
    var customGasLimitPublisher: AnyPublisher<BigUInt?, Never> { get }

    func didSelectFeeOption(_ feeOption: FeeOption)
    func didChangeCustomFee(_ value: Fee?)
    func didChangeCustomFeeGasPrice(_ value: BigUInt?)
    func didChangeCustomFeeGasLimit(_ value: BigUInt?)
}

class SendFeeViewModel: ObservableObject {
    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var showCustomFeeFields: Bool = false

    let customFeeModel: SendCustomFeeInputFieldModel?
    let customFeeGasPriceModel: SendCustomFeeInputFieldModel?
    let customFeeGasLimitModel: SendCustomFeeInputFieldModel?

    private let input: SendFeeViewModelInput
    private let feeOptions: [FeeOption]
    private let walletInfo: SendWalletInfo
    private let customFeeInFiat = CurrentValueSubject<String?, Never>("")
    private var bag: Set<AnyCancellable> = []

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var balanceConverter = BalanceConverter()

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(input: SendFeeViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption

        #warning("[REDACTED_TODO_COMMENT]")
        if feeOptions.contains(.custom) {
            customFeeModel = SendCustomFeeInputFieldModel(
                title: Localization.sendMaxFee,
                amountPublisher: input.customFeePublisher.decimalPublisher,
                fractionDigits: 18,
                amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
                footer: Localization.sendMaxFeeFooter
            ) { enteredValue in
                let newFee: Fee?

                #warning("[REDACTED_TODO_COMMENT]")
            }

            customFeeGasPriceModel = SendCustomFeeInputFieldModel(
                title: Localization.sendGasPrice,
                amountPublisher: input.customGasPricePublisher.decimalPublisher,
                fractionDigits: 0,
                amountAlternativePublisher: .just(output: nil),
                footer: Localization.sendGasPriceFooter
            ) {
                input.didChangeCustomFeeGasPrice($0?.bigUIntValue)
            }

            customFeeGasLimitModel = SendCustomFeeInputFieldModel(
                title: Localization.sendGasLimit,
                amountPublisher: input.customGasLimitPublisher.decimalPublisher,
                fractionDigits: 0,
                amountAlternativePublisher: .just(output: nil),
                footer: Localization.sendGasLimitFooter
            ) {
                input.didChangeCustomFeeGasLimit($0?.bigUIntValue)
            }
        } else {
            customFeeModel = nil
            customFeeGasPriceModel = nil
            customFeeGasLimitModel = nil
        }

        feeRowViewModels = makeFeeRowViewModels([:])

        bind()
    }

    private func bind() {
        input.feeValues
            .sink { [weak self] feeValues in
                guard let self else { return }
                feeRowViewModels = makeFeeRowViewModels(feeValues)
            }
            .store(in: &bag)

        input
            .customFeePublisher
            .map { [weak self] customFee -> String? in
                guard
                    let self,
                    let customFee,
                    let fiatFee = balanceConverter.convertToFiat(value: customFee.amount.value, from: walletInfo.feeCurrencyId)
                else {
                    return nil
                }

                return balanceFormatter.formatFiatBalance(fiatFee)
            }
            .sink { [weak self] customFeeInFiat in
                self?.customFeeInFiat.send(customFeeInFiat)
            }
            .store(in: &bag)
    }

    private func makeFeeRowViewModels(_ feeValues: [FeeOption: LoadingValue<Fee>]) -> [FeeRowViewModel] {
        let formattedFeeValues: [FeeOption: LoadingValue<String>] = feeValues.mapValues { fee in
            switch fee {
            case .loading:
                return .loading
            case .loaded(let value):
                let formattedValue = self.feeFormatter.format(
                    fee: value.amount.value,
                    currencySymbol: walletInfo.feeCurrencySymbol,
                    currencyId: walletInfo.feeCurrencyId,
                    isFeeApproximate: walletInfo.isFeeApproximate
                )
                return .loaded(formattedValue)
            case .failedToLoad(let error):
                return .failedToLoad(error: error)
            }
        }

        return feeOptions.map { option in
            let value = formattedFeeValues[option] ?? .loading

            return FeeRowViewModel(
                option: option,
                subtitle: value,
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == option
                }, set: { root, newValue in
                    if newValue {
                        self.selectFeeOption(option)
                    }
                })
            )
        }
    }

    private func selectFeeOption(_ feeOption: FeeOption) {
        selectedFeeOption = feeOption
        input.didSelectFeeOption(feeOption)
        showCustomFeeFields = feeOption == .custom
    }
}

// MARK: - private extensions

private extension DecimalNumberTextField.DecimalValue {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: value)
    }
}

private extension AnyPublisher where Output == Fee?, Failure == Never {
    var decimalPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> {
        map { value in
            if let value = value?.amount.value {
                return .external(value)
            } else {
                return nil
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> {
        map { value in
            if let decimal = value?.decimal {
                return .external(decimal)
            } else {
                return nil
            }
        }
        .eraseToAnyPublisher()
    }
}
