//
//  SendDestinationViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class DestinationViewModelInputOutputMock: DestinationViewModelInput, DestinationViewModelOutput {
    func destinationDidChanged(_ address: SendAddress?) {}

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {}
}
