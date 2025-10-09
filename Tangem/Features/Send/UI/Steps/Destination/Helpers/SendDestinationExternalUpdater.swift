//
//  SendDestinationExternalUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendDestinationExternalUpdatableViewModel {
    func externalUpdate(address: SendDestination)
    func externalUpdate(additionalField: SendDestinationAdditionalField)
}

struct SendDestinationExternalUpdater {
    private let viewModel: any SendDestinationExternalUpdatableViewModel

    init(viewModel: any SendDestinationExternalUpdatableViewModel) {
        self.viewModel = viewModel
    }

    func externalUpdate(address: SendDestination) {
        viewModel.externalUpdate(address: address)
    }

    func externalUpdate(additionalField: SendDestinationAdditionalField) {
        viewModel.externalUpdate(additionalField: additionalField)
    }
}
