//
//  SendAmountContainerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class SendAmountContainerViewModel: ObservableObject, Identifiable {
    let walletName: String
    let balance: String

    let tokenIconName: String
    let tokenIconURL: URL?
    let tokenIconCustomTokenColor: Color?
    let tokenIconBlockchainIconName: String?
    let isCustomToken: Bool

    var decimalValue: Binding<DecimalNumberTextField.DecimalValue?>
    let amountFractionDigits: Int
    @Published var amountAlternative: String = ""
    @Published var error: String?

    private var bag: Set<AnyCancellable> = []

    init(
        walletName: String,
        balance: String,
        tokenIconName: String,
        tokenIconURL: URL?,
        tokenIconCustomTokenColor: Color?,
        tokenIconBlockchainIconName: String?,
        isCustomToken: Bool,
        amountFractionDigits: Int,
        amountAlternativePublisher: AnyPublisher<String, Never>,
        decimalValue: Binding<DecimalNumberTextField.DecimalValue?>,
        errorPublisher: AnyPublisher<Error?, Never>
    ) {
        self.walletName = walletName
        self.balance = balance
        self.tokenIconName = tokenIconName
        self.tokenIconURL = tokenIconURL
        self.tokenIconCustomTokenColor = tokenIconCustomTokenColor
        self.tokenIconBlockchainIconName = tokenIconBlockchainIconName
        self.isCustomToken = isCustomToken
        self.decimalValue = decimalValue
        self.amountFractionDigits = amountFractionDigits
        self.decimalValue = decimalValue

        amountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)

        errorPublisher
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
