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
    var isBest: Bool { provider.value?.badge == .bestRate }
    var isFCAWarningList: Bool { provider.value?.badge == .fcaWarning }
}

extension SendSwapProviderCompactViewData {
    struct ProviderData {
        let provider: ExpressProvider
        let canSelectAnother: Bool
        let badge: ExpressProviderFormatter.ProviderBadge?
    }
}
