//
//  CollectiblesRegionRestrictionsSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct CollectiblesRegionRestrictionsSheet: View {
    let action: () -> Void

    var body: some View {
        ModalStatus(
            .warning,
            title: Localization.collectiblesRegionRestrictionsTitle,
            description: Localization.collectiblesRegionRestrictionsSubtitle
        )
        .actions(primary: TangemUI.Button(label: Localization.commonClose, accessibilityLabel: nil, action: action))
    }
}

// MARK: - Previews

#Preview {
    CollectiblesRegionRestrictionsSheet(action: {})
}
