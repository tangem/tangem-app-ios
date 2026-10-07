//
//  UtilGraphShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct UtilGraphShowcase: View {
    @State private var direction: UtilGraph.Direction = .positive
    @State private var isLoading = false
    @State private var width: CGFloat = 48
    @State private var height: CGFloat = 32

    var body: some View {
        DSShowcase("UtilGraph") { controls in
            controls.picker("Direction", $direction)
            controls.toggle("Loading", $isLoading)
            controls.value("Width", $width, in: 16 ... 320, step: 1)
            controls.value("Height", $height, in: 16 ... 120, step: 1)
        } stage: {
            UtilGraph(values: Self.values(for: direction))
                .direction(direction)
                .isLoading(isLoading)
                .frame(width: width, height: height)
        } matrix: {
            DSShowcaseMatrix(rows: UtilGraph.Direction.allCases, columns: [false, true], columnLabel: { $0 ? "loading" : "loaded" }) { direction, isLoading in
                UtilGraph(values: Self.values(for: direction))
                    .direction(direction)
                    .isLoading(isLoading)
                    .frame(width: 48, height: 32)
            }
        }
    }

    private static func values(for direction: UtilGraph.Direction) -> [Double] {
        switch direction {
        case .positive: [2, 4, 3, 5, 6, 5.5, 8, 9]
        case .neutral: [5, 5.2, 4.9, 5.1, 5, 5.05, 4.95, 5]
        case .negative: [9, 7, 8, 5, 6, 4, 3, 2]
        }
    }
}
#endif
