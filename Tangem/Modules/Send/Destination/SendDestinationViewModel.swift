//
//  SendDestinationViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI
import Combine

protocol SendDestinationInput {
    var destinationText: String { get set }
    var destinationTextBinding: Binding<String> { get }

    var destinationAdditionalFieldText: String { get set }
    var destinationAdditionalFieldTextBinding: Binding<String> { get }
}

protocol SendDestinationValidator {
    var destinationError: AnyPublisher<Error?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { get }
}

class SendDestinationViewModel: ObservableObject {
    var destination: Binding<String>
    var additionalField: Binding<String>

    @Published var destinationErrorText: String?
    @Published var destinationAdditionalFieldErrorText: String?

    init(input: SendDestinationInput, validator: SendDestinationValidator) {
        destination = input.destinationTextBinding
        additionalField = input.destinationAdditionalFieldTextBinding

        validator
            .destinationError
            .map {
                $0?.localizedDescription
            }
            .assign(to: &$destinationErrorText) // weak

        validator
            .destinationAdditionalFieldError
            .map {
                $0?.localizedDescription
            }
            .assign(to: &$destinationAdditionalFieldErrorText) // weak
    }
}
