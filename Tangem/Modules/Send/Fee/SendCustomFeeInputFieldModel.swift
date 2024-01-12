//
//  SendCustomFeeInputFieldModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import SwiftUI

class SendCustomFeeInputFieldModel: ObservableObject, Identifiable {
    let title: String
    let fractionDigits: Int
    let footer: String

    @Published var amount: DecimalNumberTextField.DecimalValue? = nil
    @Published var amountAlternative: String?

    private var bag: Set<AnyCancellable> = []
    private let onFieldChange: (BigUInt?) -> Void

    init(
        title: String,
        amountPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never>,
        fractionDigits: Int,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        footer: String,
        didChangeField: @escaping (BigUInt?) -> Void
    ) {
        self.title = title
        self.fractionDigits = fractionDigits
        self.footer = footer
        onFieldChange = didChangeField

        amountPublisher
            .assign(to: \.amount, on: self, ownership: .weak)
            .store(in: &bag)

        amountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
