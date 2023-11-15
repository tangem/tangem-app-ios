//
//  SendDestinationSummaryViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SendDestinationSummaryViewData: Identifiable {
    let id = UUID()
    let type: Type
}

extension SendDestinationSummaryViewData {
    enum `Type` {
        case address(address: String)
        case additionalField(type: SendAdditionalFields, value: String)
    }
}
