//
//  SendDestinationSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class SendDestinationSummaryViewModel: Identifiable {
    let type: Type

    init(type: Type) {
        self.type = type
    }
}

extension SendDestinationSummaryViewModel {
    enum `Type` {
        case address(address: String)
        case additionalField(type: SendAdditionalFields, value: String)
    }
}
