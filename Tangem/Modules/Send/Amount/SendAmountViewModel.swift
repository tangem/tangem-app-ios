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

    var blockchain: Blockchain { get }
    var amountType: Amount.AmountType { get }

    func setAmount(_ amount: Amount?)
    func useMaxAmount()
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
    @Published var amountAlternative: String = ""
    @Published var error: String?

    private let input: SendAmountViewModelInput
    private let walletInfo: SendWalletInfo
    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
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

    func didTapMaxAmount() {
        input.useMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        $amount
            .removeDuplicates { $0?.value == $1?.value }
            // We skip the first nil value from the text field
            .dropFirst()
            .filter {
                $0?.isInternal ?? true
            }
            .sink { [weak self] amount in
                guard let self else { return }
                if useFiatCalculation {
                    (input as! SendModel).setFiat(amount?.value)
                } else {
                    (input as! SendModel).setCrypto(amount?.value)
                }
                print("ZZZ setting model amount", useFiatCalculation, amount?.value)
            }
            .store(in: &bag)

        let sendModel = input as! SendModel
        Publishers.CombineLatest3($useFiatCalculation, sendModel.cryptoFormattedPublisher, sendModel.fiatFormattedPublisher)
            .map { useFiatCalculation, cryptoFormatted, fiatFormatted in
                useFiatCalculation ? cryptoFormatted : fiatFormatted
            }
            .removeDuplicates()
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest3($useFiatCalculation, sendModel.cryptoPublisher, sendModel.fiatPublisher)
            .map { useFiatCalculation, crypto, fiat in
                useFiatCalculation ? fiat : crypto
            }
            .removeDuplicates()
            .sink { newAmount in
                print("ZZZ updating view amount", newAmount)
                if let newAmount {
                    self.amount = .external(newAmount)
                } else {
                    self.amount = nil
                }
            }
            .store(in: &bag)
    }
}
