//
//  Separator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct Separator: View {
    @Environment(\.displayScale) private var displayScale

    private let height: Height
    private let color: Color
    private let axis: Axis

    private var heightValue: Double {
        switch height {
        case .exact(let value):
            return value
        case .minimal:
            return 1.0 / displayScale
        }
    }

    var body: some View {
        switch axis {
        case .horizontal:
            color
                .frame(height: heightValue)
        case .vertical:
            color
                .frame(width: heightValue)
        }
    }

    init(height: Height = .exact(1), color: Color, axis: Axis = .horizontal) {
        self.height = height
        self.color = color
        self.axis = axis
    }
}

extension Separator {
    enum Height {
        case exact(Double)
        case minimal
    }
}
