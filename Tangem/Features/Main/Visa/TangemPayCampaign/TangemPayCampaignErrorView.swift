//
//  TangemPayCampaignErrorView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct TangemPayCampaignErrorView: View {
    let onRetry: () -> Void
    let onClose: () -> Void

    var body: some View {
        StatusScreen(
            title: Localization.tangempayCampaignErrorTitle,
            description: Localization.tangempayCampaignErrorDescription,
            actionTitle: Localization.commonClose,
            action: onClose
        )
        .appearance(.error)
        .secondaryAction(title: Localization.commonRetry, action: onRetry)
    }
}
