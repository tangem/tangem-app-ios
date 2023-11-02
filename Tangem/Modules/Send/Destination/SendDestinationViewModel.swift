//
//  SendDestinationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendDestinationViewModelInput {
    var destinationTextBinding: Binding<String> { get }
    var destinationAdditionalFieldTextBinding: Binding<String> { get }

    var destinationError: AnyPublisher<Error?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { get }
}

class SendDestinationViewModel: ObservableObject {
    var destination: Binding<String>
    var additionalField: Binding<String>

    @Published var destinationErrorText: String?
    @Published var destinationAdditionalFieldErrorText: String?

    init(input: SendDestinationViewModelInput) {
        destination = input.destinationTextBinding
        additionalField = input.destinationAdditionalFieldTextBinding

        #warning("weak")
        input
            .destinationError
            .map {
                $0?.localizedDescription
            }
            .assign(to: &$destinationErrorText)

        #warning("weak")
        input
            .destinationAdditionalFieldError
            .map {
                $0?.localizedDescription
            }
            .assign(to: &$destinationAdditionalFieldErrorText)
    }
}
