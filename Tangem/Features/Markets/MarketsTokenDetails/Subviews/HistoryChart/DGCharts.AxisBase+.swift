//
//  DGCharts.AxisBase+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import DGCharts

extension AxisBase {
    func matchesAxisMinimum(_ value: Double) -> Bool {
        abs(value - axisMinimum) <= boundMatchingTolerance
    }

    func matchesAxisMaximum(_ value: Double) -> Bool {
        abs(value - axisMaximum) <= boundMatchingTolerance
    }

    private var boundMatchingTolerance: Double {
        axisRange * 1e-9
    }
}
