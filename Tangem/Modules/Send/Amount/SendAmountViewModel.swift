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

protocol SendAmountViewModelInput {
    var walletName: String { get }
    var balance: String { get }
    var tokenIconName: String { get }
    var tokenIconURL: URL? { get }
    var tokenIconCustomTokenColor: Color? { get }
    var tokenIconBlockchainIconName: String? { get }
    var isCustomToken: Bool { get }
    var amountFractionDigits: Int { get }
    var amountAlternativePublisher: AnyPublisher<String, Never> { get }
    var decimalValue: Binding<DecimalNumberTextField.DecimalValue?> { get }
    var amountError: AnyPublisher<Error?, Never> { get }

    var isFiatCalculation: Bool { get }
    var cryptoCurrencyCode: String { get }
    var fiatCurrencyCode: String { get }
}

protocol SendAmountViewModelDelegate: AnyObject {
    func didSelectCurrencyOption(isFiat: Bool)
    func didTapMaxAmount()
}

class SendAmountViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String
    let tokenIconName: String
    let tokenIconURL: URL?
    let tokenIconCustomTokenColor: Color?
    let tokenIconBlockchainIconName: String?
    let isCustomToken: Bool
    let cryptoCurrencyCode: String
    let fiatCurrencyCode: String
    let amountFractionDigits: Int

    var decimalValue: Binding<DecimalNumberTextField.DecimalValue?>

    @Published var currencyOption: CurrencyOption
    @Published var amountAlternative: String = ""
    @Published var error: String?

    weak var delegate: SendAmountViewModelDelegate?

    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput) {
        walletName = input.walletName
        balance = input.balance
        tokenIconName = input.tokenIconName
        tokenIconURL = input.tokenIconURL
        tokenIconCustomTokenColor = input.tokenIconCustomTokenColor
        tokenIconBlockchainIconName = input.tokenIconBlockchainIconName
        isCustomToken = input.isCustomToken
        decimalValue = input.decimalValue
        amountFractionDigits = input.amountFractionDigits
        decimalValue = input.decimalValue

        currencyOption = input.isFiatCalculation ? .fiat : .crypto
        cryptoCurrencyCode = input.cryptoCurrencyCode
        fiatCurrencyCode = input.fiatCurrencyCode

        bind(from: input)
    }

    func didTapMaxAmount() {
        delegate?.didTapMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)

        $currencyOption
            .sink { [weak self] option in
                let isFiat = (option == .fiat)
                self?.delegate?.didSelectCurrencyOption(isFiat: isFiat)
            }
            .store(in: &bag)
    }
}

extension SendAmountViewModel {
    enum CurrencyOption: String, CaseIterable, Identifiable {
        case crypto
        case fiat

        var id: Self { self }
    }
}
