//
//  View+style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func style(_ font: Font, color: Color) -> some View {
        self
            .font(font)
            .foregroundStyle(color)
    }
}
