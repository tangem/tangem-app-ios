//
//  UtilPriceChangeShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct UtilPriceChangeShowcase: View {
    @State private var direction: UtilPriceChange.Direction = .positive
    @State private var value = "2.08%"
    @State private var isUpdating = false

    var body: some View {
        DSShowcase("UtilPriceChange") { controls in
            controls.picker("Direction", $direction)
            controls.text("Value", $value)
            controls.toggle("Updating", $isUpdating)
        } stage: {
            UtilPriceChange(value: value, direction: direction)
                .updating(isUpdating)
        } matrix: {
            DSShowcaseMatrix(rows: UtilPriceChange.Direction.allCases, columns: [false, true], columnLabel: { $0 ? "updating" : "idle" }) { direction, isUpdating in
                UtilPriceChange(value: Self.sampleValue(for: direction), direction: direction)
                    .updating(isUpdating)
            }
        }
    }

    private static func sampleValue(for direction: UtilPriceChange.Direction) -> String {
        switch direction {
        case .positive: "2.08%"
        case .neutral: "0.00%"
        case .negative: "13.47%"
        }
    }
}
#endif
