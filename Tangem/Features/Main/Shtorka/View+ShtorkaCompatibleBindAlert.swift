//
//  View+ShtorkaCompatibleBindAlert.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

extension View {
    func shtorkaCompatibleBindAlert(_ item: Binding<AlertBinder?>) -> some View {
        background(
            Color.clear
                .shtorkaCompatibleAlert(item: item) { $0.alert }
        )
    }
}
