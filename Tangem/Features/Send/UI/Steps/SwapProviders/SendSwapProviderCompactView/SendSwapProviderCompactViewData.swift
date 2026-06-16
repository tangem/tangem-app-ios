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

    var isTappable: Bool { provider.value?.canSelectAnother == true }
    var isBest: Bool { badge?.isBest == true }
    var isFCAWarningList: Bool { badge == .fcaWarning }

    private var badge: ExpressProviderFormatter.ProviderBadge? { provider.value?.badge }
}

extension SendSwapProviderCompactViewData {
    struct ProviderData {
        let provider: ExpressProvider
        let canSelectAnother: Bool
        let badge: ExpressProviderFormatter.ProviderBadge?
    }
}
