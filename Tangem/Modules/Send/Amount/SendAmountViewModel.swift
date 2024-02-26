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
    var amountValue: Amount? { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    func prepareForSendingMaxAmount()
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

    @Published var amount: DecimalNumberTextField.DecimalValue? = nil
    @Published var useFiatCalculation = false
    @Published var amountAlternative: String?
    @Published var error: String?
    @Published var animatingAuxiliaryViewsOnAppear = false

    private weak var fiatCryptoAdapter: SendFiatCryptoAdapter?

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

        showCurrencyPicker = walletInfo.currencyId != nil
        cryptoIconURL = walletInfo.cryptoIconURL
        cryptoCurrencyCode = walletInfo.cryptoCurrencyCode
        fiatIconURL = walletInfo.fiatIconURL
        fiatCurrencyCode = walletInfo.fiatCurrencyCode

        bind(from: input)
    }

    func onAppear() {
        fiatCryptoAdapter?.setCrypto(input.amountValue?.value)

        if animatingAuxiliaryViewsOnAppear {
            withAnimation(SendView.Constants.defaultAnimation) {
                animatingAuxiliaryViewsOnAppear = false
            }
        }
    }

    func setFiatCryptoAdapter(_ fiatCryptoAdapter: SendFiatCryptoAdapter) {
        self.fiatCryptoAdapter = fiatCryptoAdapter
        bind(from: fiatCryptoAdapter)
    }

    func setUserInputAmount(_ userInputAmount: DecimalNumberTextField.DecimalValue?) {
        amount = userInputAmount
    }

    func didTapMaxAmount() {
        guard let balanceValue else { return }

        fiatCryptoAdapter?.setCrypto(balanceValue)
        input.prepareForSendingMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        $amount
            .removeDuplicates { $0?.value == $1?.value }
            .dropFirst()
            .sink { [weak self] decimal in
                self?.fiatCryptoAdapter?.setAmount(decimal)
            }
            .store(in: &bag)

        $useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] useFiatCalculation in
                self?.fiatCryptoAdapter?.setUseFiatCalculation(useFiatCalculation)
            }
            .store(in: &bag)
    }

    private func bind(from fiatCryptoAdapter: SendFiatCryptoAdapter) {
        fiatCryptoAdapter
            .amountAlternative
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension SendAmountViewModel: AuxiliaryViewAnimatable {
    func setAnimatingAuxiliaryViewsOnAppear(_ animatingAuxiliaryViewsOnAppear: Bool) {
        self.animatingAuxiliaryViewsOnAppear = animatingAuxiliaryViewsOnAppear
    }
}

extension SendAmountViewModel: SendFiatCryptoAdapterInput {
    var amountPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> {
        $amount.eraseToAnyPublisher()
    }
}
