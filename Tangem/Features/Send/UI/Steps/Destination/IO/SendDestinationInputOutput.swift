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
    var destination: SendDestination? { get }
    var destinationAdditionalField: SendDestinationAdditionalField { get }

    var destinationPublisher: AnyPublisher<SendDestination?, Never> { get }
    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { get }
}

protocol SendDestinationOutput: AnyObject {
    func destinationDidChanged(_ address: SendDestination?)
    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField)
}

protocol SendDestinationAccountOutput: AnyObject {
    func setDestinationAccountInfo(
        analyticsProvider: (any AccountModelAnalyticsProviding)?,
        tokenHeader: ExpressInteractorTokenHeader?
    )
}
