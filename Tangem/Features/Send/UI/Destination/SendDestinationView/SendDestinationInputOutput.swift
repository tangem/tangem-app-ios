//
//  SendDestinationInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendDestinationInput: AnyObject {
    var destination: SendAddress? { get }
    var destinationAdditionalField: SendDestinationAdditionalField { get }

    var destinationPublisher: AnyPublisher<SendAddress?, Never> { get }
    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { get }
}

protocol SendDestinationOutput: AnyObject {
    func destinationDidChanged(_ address: SendAddress?)
    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField)
}
