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
    
    var body: some View {
        Color.tangemGrayLight5
            .frame(width: nil, height: height, alignment: .center)
            .padding(.vertical, padding)
    }
    
    init(height: Double = 1.0, padding: Double = 4) {
        self.height = height
        self.padding = padding
    }
}
