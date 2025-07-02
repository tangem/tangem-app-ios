//
//  HederaFeeParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HederaFeeParams: FeeParameters {
    /// UI only, this fee must be excluded when building transaction
    let additionalHBARFee: Decimal
}
