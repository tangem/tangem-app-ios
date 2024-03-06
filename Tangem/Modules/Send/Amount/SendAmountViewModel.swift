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
    let amountFractionDigits: Int
    let windowWidth: CGFloat

    @Published var decimalNumberTextFieldStateObject: DecimalNumberTextField.StateObject
    @Published var useFiatCalculation = false
    @Published var amountAlternative: String?
    @Published var error: String?
    @Published var animatingAuxiliaryViewsOnAppear = false

    private var fiatCryptoAdapter: SendFiatCryptoAdapter?

    private let input: SendAmountViewModelInput
    private let balanceValue: Decimal?
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        balanceValue = walletInfo.balanceValue
        walletName = walletInfo.walletName
        balance = walletInfo.balance
        tokenIconInfo = walletInfo.tokenIconInfo
        amountFractionDigits = walletInfo.amountFractionDigits
        windowWidth = UIApplication.shared.windows.first?.frame.width ?? 400
        decimalNumberTextFieldStateObject = .init(maximumFractionDigits: walletInfo.amountFractionDigits)

        showCurrencyPicker = walletInfo.currencyId != nil
        cryptoIconURL = walletInfo.cryptoIconURL
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode
        fiatIconURL = walletInfo.fiatIconURL
        fiatCurrencyCode = walletInfo.fiatCurrencyCode

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
            withAnimation(SendView.Constants.defaultAnimation) {
                animatingAuxiliaryViewsOnAppear = false
            }
        }
    }

    func setUserInputAmount(_ userInputAmount: Decimal?) {
        decimalNumberTextFieldStateObject.update(value: userInputAmount)
    }

    func didTapMaxAmount() {
        guard let balanceValue else { return }

        provideButtonHapticFeedback()

        fiatCryptoAdapter?.setCrypto(balanceValue)
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        decimalNumberTextFieldStateObject
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
                viewModel.decimalNumberTextFieldStateObject.update(maximumFractionDigits: maximumFractionDigits)
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

extension SendAmountViewModel: AuxiliaryViewAnimatable {
    func setAnimatingAuxiliaryViewsOnAppear(_ animatingAuxiliaryViewsOnAppear: Bool) {
        self.animatingAuxiliaryViewsOnAppear = animatingAuxiliaryViewsOnAppear
    }
}

extension SendAmountViewModel: SendFiatCryptoAdapterInput {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        decimalNumberTextFieldStateObject.valuePublisher
    }
}

extension SendAmountViewModel: SendFiatCryptoAdapterOutput {
    func setAmount(_ decimal: Decimal?) {
        input.setAmount(decimal)
    }
}
