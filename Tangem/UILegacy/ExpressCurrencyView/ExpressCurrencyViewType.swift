//
//  ExpressCurrencyViewType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum ExpressCurrencyViewType: Hashable {
    case send
    case receive

    func actionName() -> String {
        switch self {
        case .send: Localization.swappingFromTitle
        case .receive: Localization.swappingToTitle
        }
    }
}
