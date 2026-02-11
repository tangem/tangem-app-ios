//
//  FeeSelectorFeeCoverageState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
enum FeeCoverage {
    case covered(feeValue: Decimal)
    case uncovered(missingAmount: Decimal)
    case undefined
}
