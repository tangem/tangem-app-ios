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
//    let fractionDigits: Int
    let footer: String

    @Published var decimalNumberTextFieldStateObject: DecimalNumberTextField.StateObject
    @Published var amountAlternative: String?

    private var bag: Set<AnyCancellable> = []
    private let onFieldChange: (Decimal?) -> Void

    init(
        title: String,
        amountPublisher: AnyPublisher<Decimal?, Never>,
        fractionDigits: Int,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        footer: String,
        onFieldChange: @escaping (Decimal?) -> Void
    ) {
        self.title = title
        decimalNumberTextFieldStateObject = .init(maximumFractionDigits: fractionDigits)
        self.footer = footer
        self.onFieldChange = onFieldChange

        amountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { (self, amount) in
                guard amount != self.decimalNumberTextFieldStateObject.value else { return }

                self.decimalNumberTextFieldStateObject.update(value: amount)
            }
            .store(in: &bag)

        decimalNumberTextFieldStateObject.valuePublisher
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { (self, value) in
                self.onFieldChange(value)
            }
            .store(in: &bag)

        amountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
