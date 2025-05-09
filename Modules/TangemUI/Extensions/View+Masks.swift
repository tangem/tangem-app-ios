//
//  View+Masks.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func reverseMask<Mask: View>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            Rectangle()
                .ignoresSafeArea()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        )
    }
}
