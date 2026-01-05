//
//  FeeSelectorFee.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct FeeSelectorFee {
    let option: FeeOption
    let value: LoadingResult<BSDKFee, any Error>
}
