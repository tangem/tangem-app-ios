//
//  CollectiblesTurboModeInfoSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct CollectiblesTurboModeInfoSheet: View {
    let action: () -> Void

    var body: some View {
        ModalStatus(
            .info,
            title: Localization.collectiblesTurboModeBottomsheetTitle,
            description: Localization.collectiblesTurboModeBottomsheetMessage
        )
        .actions(primary: TangemUI.Button(label: Localization.commonGotIt, accessibilityLabel: nil, action: action))
    }
}

// MARK: - Previews

#Preview {
    CollectiblesTurboModeInfoSheet(action: {})
}
