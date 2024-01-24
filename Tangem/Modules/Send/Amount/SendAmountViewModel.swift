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
        guard let maxCryptoAmount = (input as! SendModel).walletMaxAmount else { return }
        (input as! SendModel).setCrypto(maxCryptoAmount)
        let sendModel = (input as! SendModel)
        guard let newAmount = useFiatCalculation ? sendModel.cryptoFiatAmount?.fiat : sendModel.cryptoFiatAmount?.crypto else {
            return
        }

        amount = .external(newAmount)
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

//        input
//            .amountInputPublisher
//            .sink { [weak self] amount in
//                self?.amount = self?.fromAmount(amount)
//            }
//            .store(in: &bag)
//
//        $amount
//            .sink { [weak self] amount in
//                guard let self else { return }
//                input.setAmount(toAmount(amount))
//            }
//            .store(in: &bag)

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

        $useFiatCalculation
            .sink { [weak self] useFiatCalculation in
                guard let self else { return }
                let sendModel = input as! SendModel
                let userInputAmount = useFiatCalculation ? sendModel.cryptoFiatAmount?.fiat : sendModel.cryptoFiatAmount?.crypto
                if let userInputAmount {
                    amount = .external(userInputAmount)
                } else {
                    amount = nil
                }
                print("ZZZ changing input after fiat/crypto change", userInputAmount, "(\(sendModel.cryptoFiatAmount?.crypto), \(sendModel.cryptoFiatAmount?.fiat))")
            }
            .store(in: &bag)
    }

    private func fromAmount(_ amount: Amount?) -> DecimalNumberTextField.DecimalValue? {
        if let amount {
            return DecimalNumberTextField.DecimalValue.external(amount.value)
        } else {
            return nil
        }
    }

    private func toAmount(_ decimalValue: DecimalNumberTextField.DecimalValue?) -> Amount? {
        if let decimalValue {
            return Amount(with: input.blockchain, type: input.amountType, value: decimalValue.value)
        } else {
            return nil
        }
    }
}
