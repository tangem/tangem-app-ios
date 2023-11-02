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
    var amountTextBinding: Binding<String> { get }
    var amountError: AnyPublisher<Error?, Never> { get }
}

class SendAmountViewModel: ObservableObject {
    var amountText: Binding<String>

    @Published var amountError: String?

    init(input: SendAmountViewModelInput) {
        amountText = input.amountTextBinding

        #warning("weak")
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: &$amountError)
    }
}
