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
    let footer: String?
    let fieldSuffix: String?

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var amountAlternative: String?

    let onFocusChanged: ((Bool) -> Void)?

    private var bag: Set<AnyCancellable> = []
    private let onFieldChange: (Decimal?) -> Void

    init(
        title: String,
        amountPublisher: AnyPublisher<Decimal?, Never>,
        fieldSuffix: String?,
        fractionDigits: Int,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        footer: String?,
        onFieldChange: @escaping (Decimal?) -> Void,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.fieldSuffix = fieldSuffix
        self.footer = footer
        self.onFieldChange = onFieldChange
        self.onFocusChanged = onFocusChanged

        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: fractionDigits)

        amountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { (self, amount) in
                guard amount != self.decimalNumberTextFieldViewModel.value else { return }

                self.decimalNumberTextFieldViewModel.update(value: amount)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
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
