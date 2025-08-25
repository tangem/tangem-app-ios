//
//  SendExternalDestinationUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendExternalDestinationUpdatableViewModel {
    func externalUpdate(address: SendAddress)
    func externalUpdate(additionalField: SendDestinationAdditionalField)
}

struct SendExternalDestinationUpdater {
    private let viewModel: any SendExternalDestinationUpdatableViewModel

    init(viewModel: any SendExternalDestinationUpdatableViewModel) {
        self.viewModel = viewModel
    }

    func externalUpdate(address: SendAddress) {
        viewModel.externalUpdate(address: address)
    }

    func externalUpdate(additionalField: SendDestinationAdditionalField) {
        viewModel.externalUpdate(additionalField: additionalField)
    }
}
