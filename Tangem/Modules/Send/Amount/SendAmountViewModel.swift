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
    var amountInputPublisher: AnyPublisher<Amount?, Never> { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    var amountType: Amount.AmountType { get }
    var currencySymbol: String { get }

    func setAmount(_ amount: Amount?)
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
    private let maxAmount: Decimal?
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        maxAmount = walletInfo.balanceAmount
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

    func setUserInputAmount(_ userInputAmount: DecimalNumberTextField.DecimalValue?) {
        amount = userInputAmount
    }

    func setFiatCryptoAdapter(_ fiatCryptoAdapter: SendFiatCryptoAdapter) {
        self.fiatCryptoAdapter = fiatCryptoAdapter
        fiatCryptoAdapter
            .amountAlternative
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func onAppear() {
        if animatingAuxiliaryViewsOnAppear {
            withAnimation(SendView.Constants.defaultAnimation) {
                animatingAuxiliaryViewsOnAppear = false
            }
        }
    }

    func didTapMaxAmount() {
        guard let maxAmount else { return }

        amount = .external(maxAmount)
        input.prepareForSendingMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension SendAmountViewModel: AuxiliaryViewAnimatable {
    func setAnimatingAuxiliaryViewsOnAppear(_ animatingAuxiliaryViewsOnAppear: Bool) {
        self.animatingAuxiliaryViewsOnAppear = animatingAuxiliaryViewsOnAppear
    }
}
