//
//  Separator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct Separator: View {
    let height: Double
    let padding: Double
    let color: Color

    var body: some View {
        color
            .frame(width: nil, height: height, alignment: .center)
            .padding(.vertical, padding)
    }

    init(height: Double = 1.0, padding: Double = 4, color: Color = Color.tangemGrayLight5) {
        self.height = height
        self.padding = padding
        self.color = color
    }
}
