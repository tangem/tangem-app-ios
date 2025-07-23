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

    func autosave(enabled: Bool)
    func save()
}

class CommonSendNewDestinationInteractorSaver: SendNewDestinationInteractorSaver {
    private weak var output: SendDestinationOutput?

    private var cachedDestination: SendAddress?
    private var cachedAdditionalField: SendDestinationAdditionalField

    private var isAutosaveEnabled: Bool = true

    init(
        input: SendDestinationInput,
        output: SendDestinationOutput
    ) {
        cachedDestination = input.destination
        cachedAdditionalField = input.destinationAdditionalField

        self.output = output
    }

    func update(address: SendAddress?) {
        cachedDestination = address

        if isAutosaveEnabled {
            output?.destinationDidChanged(cachedDestination)
        }
    }

    func update(additionalField: SendDestinationAdditionalField) {
        cachedAdditionalField = additionalField

        if isAutosaveEnabled {
            output?.destinationAdditionalParametersDidChanged(cachedAdditionalField)
        }
    }

    func autosave(enabled: Bool) {
        isAutosaveEnabled = enabled
    }

    func save() {
        output?.destinationDidChanged(cachedDestination)
        output?.destinationAdditionalParametersDidChanged(cachedAdditionalField)
    }
}
