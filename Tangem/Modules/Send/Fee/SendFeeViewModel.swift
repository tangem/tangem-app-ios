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
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }

    var customFeeSatoshiPerByte: Int? { get }
    var customGasLimit: BigUInt? { get }
    var customGasPrice: BigUInt? { get }

    var customFeePublisher: AnyPublisher<Fee?, Never> { get }
    var customFeeSatoshiPerBytePublisher: AnyPublisher<Int?, Never> { get }
    var customGasPricePublisher: AnyPublisher<BigUInt?, Never> { get }
    var customGasLimitPublisher: AnyPublisher<BigUInt?, Never> { get }

    var canIncludeFeeIntoAmount: Bool { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    func didSelectFeeOption(_ feeOption: FeeOption)
    func didChangeCustomFee(_ value: Fee?)
    func didChangeCustomSatoshiPerByte(_ value: Int?)
    func didChangeCustomFeeGasPrice(_ value: BigUInt?)
    func didChangeCustomFeeGasLimit(_ value: BigUInt?)
    func didChangeFeeInclusion(_ isFeeIncluded: Bool)
}

class SendFeeViewModel: ObservableObject {
    let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)

    weak var router: SendFeeRoutable?

    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var showCustomFeeFields: Bool = false
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false

    var didProperlyDisappear = false

    private(set) var customFeeModel: SendCustomFeeInputFieldModel?
    private(set) var customFeeSatoshiPerByteModel: SendCustomFeeInputFieldModel?
    private(set) var customFeeGasPriceModel: SendCustomFeeInputFieldModel?
    private(set) var customFeeGasLimitModel: SendCustomFeeInputFieldModel?

    private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

    @Published private var isFeeIncluded: Bool = false

    @Published private(set) var feeLevelsNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var customFeeNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var feeCoverageNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    private let notificationManager: SendNotificationManager
    private let input: SendFeeViewModelInput
    private let feeOptions: [FeeOption]
    private let walletInfo: SendWalletInfo
    private let customFeeService: CustomFeeService?
    private let customFeeInFiat = CurrentValueSubject<String?, Never>("")
    private var customGasPriceBeforeEditing: BigUInt?
    private var bag: Set<AnyCancellable> = []

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var balanceConverter = BalanceConverter()

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(input: SendFeeViewModelInput, notificationManager: SendNotificationManager, customFeeService: CustomFeeService?, walletInfo: SendWalletInfo) {
        self.input = input
        self.notificationManager = notificationManager
        self.customFeeService = customFeeService
        self.walletInfo = walletInfo
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption

        if feeOptions.contains(.custom) {
            createCustomFeeModels()
        }

        feeRowViewModels = makeFeeRowViewModels([:])

        bind()
    }

    func onAppear() {
        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .fee])

            withAnimation(SendView.Constants.defaultAnimation) {
                animatingAuxiliaryViewsOnAppear = false
            }
        } else {
            Analytics.log(.sendFeeScreenOpened)
        }
    }

    func onCustomGasPriceFocusChanged(focused: Bool) {
        if focused {
            customGasPriceBeforeEditing = input.customGasPrice
        } else {
            let customGasPriceAfterEditing = input.customGasPrice
            if customGasPriceAfterEditing != customGasPriceBeforeEditing {
                Analytics.log(.sendGasPriceInserted)
            }

            customGasPriceBeforeEditing = nil
        }
    }

    func openFeeExplanation() {
        router?.openFeeExplanation(url: feeExplanationUrl)
    }

    private func createCustomFeeModels() {
        customFeeModels = customFeeService?.models() ?? []

        let customFeeFooter: String?
        let customFeeTitle: String

//        let sendModel = input as! SendModel
//
//        if case .bitcoin = sendModel.blockchainNetwork.blockchain {
//            let satoshiPerBytePublisher = input
//                .customFeeSatoshiPerBytePublisher
//                .map { intValue -> Decimal? in
//                    if let intValue {
//                        Decimal(intValue)
//                    } else {
//                        nil
//                    }
//                }
//                .eraseToAnyPublisher()
//
//            customFeeSatoshiPerByteModel = SendCustomFeeInputFieldModel(
//                title: "Satoshi per byte",
//                amountPublisher: satoshiPerBytePublisher,
//                fieldSuffix: nil,
//                fractionDigits: 0,
//                amountAlternativePublisher: .just(output: nil),
//                footer: nil
//            ) { [weak self] decimalValue in
//                let intValue: Int?
//                if let decimalValue {
//                    intValue = (decimalValue as NSDecimalNumber).intValue
//                } else {
//                    intValue = nil
//                }
//
//                self?.input.didChangeCustomSatoshiPerByte(intValue)
//            }
//
        customFeeTitle = Localization.commonFeeLabel
        customFeeFooter = nil
//        } else if sendModel.blockchainNetwork.blockchain.isEvm {
//            let gasPriceFractionDigits = 9
//            let gasPriceGweiPublisher = input
//                .customGasPricePublisher
//                .decimalPublisher
//                .map { weiValue -> Decimal? in
//                    let gweiValue = weiValue?.shiftOrder(magnitude: -gasPriceFractionDigits)
//                    return gweiValue
//                }
//                .eraseToAnyPublisher()
//
//            customFeeGasPriceModel = SendCustomFeeInputFieldModel(
//                title: Localization.sendGasPrice,
//                amountPublisher: gasPriceGweiPublisher,
//                fieldSuffix: "GWEI",
//                fractionDigits: gasPriceFractionDigits,
//                amountAlternativePublisher: .just(output: nil),
//                footer: Localization.sendGasPriceFooter
//            ) { [weak self] gweiValue in
//                guard let self else { return }
//
//                let weiValue = gweiValue?.shiftOrder(magnitude: gasPriceFractionDigits)
//                input.didChangeCustomFeeGasPrice(weiValue?.bigUIntValue)
//            }
//
//            customFeeGasLimitModel = SendCustomFeeInputFieldModel(
//                title: Localization.sendGasLimit,
//                amountPublisher: input.customGasLimitPublisher.decimalPublisher,
//                fieldSuffix: nil,
//                fractionDigits: 0,
//                amountAlternativePublisher: .just(output: nil),
//                footer: Localization.sendGasLimitFooter
//            ) { [weak self] in
//                guard let self else { return }
//                input.didChangeCustomFeeGasLimit($0?.bigUIntValue)
//            }
//
//            customFeeTitle = Localization.sendMaxFee
//            customFeeFooter = Localization.sendMaxFeeFooter
//
//        } else {
//            return
//        }

        customFeeModel = SendCustomFeeInputFieldModel(
            title: customFeeTitle,
            amountPublisher: input.customFeePublisher.decimalPublisher,
            fieldSuffix: walletInfo.feeCurrencySymbol,
            fractionDigits: walletInfo.feeFractionDigits,
            amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
            footer: customFeeFooter
        ) { [weak self] enteredFee in
            guard let self else { return }
            input.didChangeCustomFee(recalculateFee(enteredFee: enteredFee, input: input, walletInfo: walletInfo))
        }
    }

    private func bind() {
        input.feeValues
            .withWeakCaptureOf(self)
            .sink { (self, feeValues) in
                self.feeRowViewModels = self.makeFeeRowViewModels(feeValues)
            }
            .store(in: &bag)

        input
            .customFeePublisher
            .withWeakCaptureOf(self)
            .map { (self, customFee) -> String? in
                guard
                    let customFee,
                    let fiatFee = self.balanceConverter.convertToFiat(value: customFee.amount.value, from: self.walletInfo.feeCurrencyId)
                else {
                    return nil
                }

                return self.balanceFormatter.formatFiatBalance(fiatFee)
            }
            .withWeakCaptureOf(self)
            .sink { (self, customFeeInFiat) in
                self.customFeeInFiat.send(customFeeInFiat)
            }
            .store(in: &bag)

        input.isFeeIncludedPublisher
            .assign(to: \.isFeeIncluded, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeLevels)
            .assign(to: \.feeLevelsNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .customFee)
            .assign(to: \.customFeeNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeIncluded)
            .assign(to: \.feeCoverageNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func makeFeeRowViewModels(_ feeValues: [FeeOption: LoadingValue<Fee>]) -> [FeeRowViewModel] {
        let formattedFeeValuePairs: [(FeeOption, LoadingValue<FormattedFeeComponents?>)] = feeValues.map { feeOption, feeValue in
            guard feeOption != .custom else {
                return (feeOption, .loaded(nil))
            }

            let result: LoadingValue<FormattedFeeComponents?>
            switch feeValue {
            case .loading:
                result = .loading
            case .loaded(let value):
                let formattedFeeComponents = self.feeFormatter.formattedFeeComponents(
                    fee: value.amount.value,
                    currencySymbol: walletInfo.feeCurrencySymbol,
                    currencyId: walletInfo.feeCurrencyId,
                    isFeeApproximate: walletInfo.isFeeApproximate
                )
                result = .loaded(formattedFeeComponents)
            case .failedToLoad(let error):
                result = .failedToLoad(error: error)
            }

            return (feeOption, result)
        }

        let formattedFeeValues = Dictionary(uniqueKeysWithValues: formattedFeeValuePairs)
        return feeOptions.map { option in
            let value = formattedFeeValues[option] ?? .loading

            return FeeRowViewModel(
                option: option,
                formattedFeeComponents: value,
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
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

        selectedFeeOption = feeOption
        input.didSelectFeeOption(feeOption)
        showCustomFeeFields = feeOption == .custom
    }

    private func recalculateFee(enteredFee: Decimal?, input: SendFeeViewModelInput, walletInfo: SendWalletInfo) -> Fee? {
        let sendModel = input as! SendModel
        if sendModel.blockchainNetwork.blockchain.isEvm {
            let feeDecimalValue = Decimal(pow(10, Double(walletInfo.feeFractionDigits)))

            guard
                let enteredFee,
                let currentGasLimit = input.customGasLimit,
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
        } else {
            return nil
        }
    }
}

extension SendFeeViewModel: AuxiliaryViewAnimatable {}

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
