//
//  MCPIntentPrimaryButton.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MCPIntentPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        TangemUI.Button(label: title, accessibilityLabel: nil, action: action)
            .styleType(.primary)
            .size(.x12)
            .horizontalLayout(.infinity)
            .padding(.top, 8)
    }
}
