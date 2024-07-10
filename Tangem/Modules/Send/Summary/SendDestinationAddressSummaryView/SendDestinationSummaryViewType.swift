//
//  SendDestinationSummaryViewType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

enum SendDestinationSummaryViewType {
    case address(address: String, corners: UIRectCorner)
    case additionalField(type: SendDestinationAdditionalFieldType, value: String)
}

extension SendDestinationSummaryViewType: Identifiable {
    var id: String {
        switch self {
        case .address(let address, _):
            return address
        case .additionalField(_, let value):
            return value
        }
    }
}
