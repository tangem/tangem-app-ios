//
//  SendDestinationInteractorSaver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendDestinationInteractorSaver {
    func update(address: SendDestination?)
    func update(additionalField: SendDestinationAdditionalField)

    func captureValue()
    func cancelChanges()
}

class CommonSendDestinationInteractorSaver: SendDestinationInteractorSaver {
    private weak var input: SendDestinationInput?
    private weak var output: SendDestinationOutput?
    var updater: SendDestinationExternalUpdater?

    private var captureDestination: SendDestination?
    private var captureAdditionalField: SendDestinationAdditionalField?

    init(input: any SendDestinationInput, output: any SendDestinationOutput) {
        self.input = input
        self.output = output
    }

    func update(address: SendDestination?) {
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
        if let captureDestination {
            output?.destinationDidChanged(captureDestination)
            updater?.externalUpdate(address: captureDestination)
        }

        if let captureAdditionalField {
            output?.destinationAdditionalParametersDidChanged(captureAdditionalField)
            updater?.externalUpdate(additionalField: captureAdditionalField)
        }
    }
}
