//
//  TangemPayUnavailableRegionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct TangemPayUnavailableRegionView: View {
    let output: (Output) -> Void

    var body: some View {
        StatusScreen(
            title: Localization.tangempayRegionUnavailableTitle,
            description: Localization.tangempayRegionUnavailableDescription,
            actionTitle: Localization.tangempayRegionUnavailableSecondaryButton,
            action: { output(.selectAnotherRegion) }
        )
        .appearance(.error)
        .secondaryAction(
            title: Localization.tangempayRegionUnavailablePrimaryButton,
            action: { output(.joinWaitlist) }
        )
    }
}

// MARK: - Output

extension TangemPayUnavailableRegionView {
    enum Output {
        case selectAnotherRegion
        case joinWaitlist
    }
}

// MARK: - Previews

#Preview {
    TangemPayUnavailableRegionView(output: { _ in })
}
