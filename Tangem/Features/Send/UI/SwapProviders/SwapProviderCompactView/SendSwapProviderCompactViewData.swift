//
//  SendSwapProviderCompactViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

struct SendSwapProviderCompactViewData {
    let provider: LoadingResult<ProviderData, String>

    var isTappable: Bool { provider.value != nil }
}

extension SendSwapProviderCompactViewData {
    struct ProviderData {
        let provider: ExpressProvider
        let isBest: Bool
    }
}
