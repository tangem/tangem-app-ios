//
//  SendNewDestinationInteractorSaver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendNewDestinationInteractorSaver {
    func update(address: SendAddress?)
    func update(additionalField: SendDestinationAdditionalField)

    func captureValue()
    func cancelChanges()
}

class CommonSendNewDestinationInteractorSaver: SendNewDestinationInteractorSaver {
    private weak var input: SendDestinationInput?
    private weak var output: SendDestinationOutput?

    private var captureDestination: SendAddress?
    private var captureAdditionalField: SendDestinationAdditionalField?

    init(input: any SendDestinationInput, output: any SendDestinationOutput) {
        self.input = input
        self.output = output
    }

    func update(address: SendAddress?) {
        output?.destinationDidChanged(address)
    }

    func update(additionalField: SendDestinationAdditionalField) {
        output?.destinationAdditionalParametersDidChanged(additionalField)
    }

    func captureValue() {
        captureDestination = input?.destination
        captureAdditionalField = input?.destinationAdditionalField
    }

    func cancelChanges() {
        output?.destinationDidChanged(captureDestination)

        if let captureAdditionalField {
            output?.destinationAdditionalParametersDidChanged(captureAdditionalField)
        }
    }
}
