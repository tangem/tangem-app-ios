//
//  SendDestinationViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

protocol SendDestinationInput {
    var destinationText: String { get set }
    var destinationTextBinding: Binding<String> { get }
}

class SendDestinationViewModel {
    var destination: Binding<String>

    init(input: SendDestinationInput) {
        destination = input.destinationTextBinding
    }
}
