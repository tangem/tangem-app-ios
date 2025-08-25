//
//  View_withCloseButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func withCloseButton(placement: ToolbarItemPlacement = .topBarLeading, action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: placement) {
                CloseButton(dismiss: action)
            }
        }
    }
}
