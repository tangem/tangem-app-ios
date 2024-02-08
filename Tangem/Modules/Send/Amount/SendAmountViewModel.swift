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
    @Published var amountAlternative: String?
    @Published var error: String?

    private let input: SendAmountViewModelInput
    private var bag: Set<AnyCancellable> = []

    private let converter: SendFiatCryptoConverter

    init(input: SendAmountViewModelInput, walletInfo: SendWalletInfo) {
        converter = SendFiatCryptoConverter(
            blockchain: input.blockchain,
            amountType: input.amountType,
            cryptoCurrencyId: walletInfo.currencyId,
            amountFractionDigits: walletInfo.amountFractionDigits
        )

        self.input = input
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
            .amountInputPublisher

            .sink { [weak self] amount in
                print("ZZZ -> model amount changed", amount)
//                if let value = amount?.value {
//                    self?.amount = .external(value)
//                } else {
//                    self?.amount = nil
//                }

                self?.converter.setModelAmount(amount?.value)
            }
            .store(in: &bag)

        $amount
            .removeDuplicates { $0?.value == $1?.value }
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
            .filter { $0?.isInternal ?? true }
            .sink { [weak self] v in
                print("ZZZ -> text input amount changed", v?.value, (v?.isInternal ?? true) ? "internal" : "external")
                self?.converter.setUserInputAmount(v)
            }
            .store(in: &bag)

        $useFiatCalculation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] useFiatCalculation in
                self?.converter.setUseFiatCalculation(useFiatCalculation)
            }
            .store(in: &bag)

        converter
            .modelAmount
            .sink { [weak self] modelAmount in
                print("ZZZ <- model amount recalculated", modelAmount)
                self?.input.setAmount(modelAmount)
            }
            .store(in: &bag)

        converter
            .userInputAmount
            .sink { [weak self] newUserInputAmount in
                print("ZZZ <- user input recalculated", newUserInputAmount?.value, (newUserInputAmount?.isInternal ?? true) ? "internal" : "external")
                self?.amount = newUserInputAmount
            }
            .store(in: &bag)

        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        converter
            .amountAlternative
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
