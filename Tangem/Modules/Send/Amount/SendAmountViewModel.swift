//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

#warning("[REDACTED_TODO_COMMENT]")

protocol SendAmountViewModelInput {
    var userInputAmountValue: Amount? { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    func setAmount(_ decimal: Decimal?)
    func didChangeFeeInclusion(_ isFeeIncluded: Bool)
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let showCurrencyPicker: Bool
    let cryptoIconURL: URL?
    let cryptoCurrencyCode: String
    let fiatIconURL: URL?
    let fiatCurrencyCode: String
    let fiatCurrencySymbol: String
    let amountFractionDigits: Int

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var useFiatCalculation = false
    @Published var amountAlternative: String?
    @Published var error: String?
    @Published var animatingAuxiliaryViewsOnAppear = false
    @Published var showSectionContent = false

    var inputFieldPrefix: String? {
        useFiatCalculation ? fiatFieldOptions.prefix : cryptoFieldOptions.prefix
    }

    var inputFieldSuffix: String? {
        useFiatCalculation ? fiatFieldOptions.suffix : cryptoFieldOptions.suffix
    }

    var hasSpaceAfterPrefix: Bool {
        useFiatCalculation ? fiatFieldOptions.hasSpaceAfterPrefix : cryptoFieldOptions.hasSpaceBeforeSuffix
    }

    var hasSpaceBeforeSuffix: Bool {
        useFiatCalculation ? fiatFieldOptions.hasSpaceAfterPrefix : cryptoFieldOptions.hasSpaceBeforeSuffix
    }

    var didProperlyDisappear = false

    private var fiatCryptoAdapter: SendFiatCryptoAdapter?

    private let input: SendAmountViewModelInput
    private let cryptoFieldOptions: SendDecimalNumberTextFieldOptions
    private let fiatFieldOptions: SendDecimalNumberTextFieldOptions
    private let balanceValue: Decimal?
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        balanceValue = walletInfo.balanceValue
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: walletInfo.amountFractionDigits)

        showCurrencyPicker = walletInfo.currencyId != nil

        cryptoIconURL = walletInfo.cryptoIconURL
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode

        let localizedCurrencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: walletInfo.fiatCurrencyCode)
        fiatIconURL = walletInfo.fiatIconURL
        fiatCurrencyCode = walletInfo.fiatCurrencyCode
        fiatCurrencySymbol = localizedCurrencySymbol ?? walletInfo.fiatCurrencyCode

        let factory = SendDecimalNumberTextFieldOptionsFactory(
            cryptoCurrencyCode: walletInfo.cryptoCurrencyCode,
            fiatCurrencyCode: walletInfo.fiatCurrencyCode
        )
        cryptoFieldOptions = factory.makeCryptoOptions()
        fiatFieldOptions = factory.makeFiatOptions()

        fiatCryptoAdapter = SendFiatCryptoAdapter(
            cryptoCurrencyId: walletInfo.currencyId,
            currencySymbol: walletInfo.cryptoCurrencyCode,
            decimals: walletInfo.amountFractionDigits,
            input: self,
            output: self
        )

        bind(from: input)
    }

    func onAppear() {
        fiatCryptoAdapter?.setCrypto(input.userInputAmountValue?.value)

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.commonSource: .amount])
        } else {
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func setUserInputAmount(_ userInputAmount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: userInputAmount)
    }

    func didTapMaxAmount() {
        guard let balanceValue else { return }

        Analytics.log(.sendMaxAmountTapped)

        provideButtonHapticFeedback()

        fiatCryptoAdapter?.setCrypto(balanceValue)
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .sink { [weak self] decimal in
                self?.fiatCryptoAdapter?.setAmount(decimal)
            }
            .store(in: &bag)

        $useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, useFiatCalculation in
                let maximumFractionDigits = useFiatCalculation ? 2 : viewModel.amountFractionDigits
                viewModel.decimalNumberTextFieldViewModel.update(maximumFractionDigits: maximumFractionDigits)
                viewModel.provideSelectionHapticFeedback()
                viewModel.fiatCryptoAdapter?.setUseFiatCalculation(useFiatCalculation)
            }
            .store(in: &bag)

        fiatCryptoAdapter?
            .amountAlternative
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func provideButtonHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func provideSelectionHapticFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

extension SendAmountViewModel: AuxiliaryViewAnimatable {}

extension SendAmountViewModel: SectionContainerAnimatable {}

extension SendAmountViewModel: SendFiatCryptoAdapterInput {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        decimalNumberTextFieldViewModel.valuePublisher
    }
}

extension SendAmountViewModel: SendFiatCryptoAdapterOutput {
    func setAmount(_ decimal: Decimal?) {
        input.setAmount(decimal)
    }
}
