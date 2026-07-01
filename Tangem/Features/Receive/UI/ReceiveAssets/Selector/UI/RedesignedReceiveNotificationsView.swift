//
//  RedesignedReceiveNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct RedesignedReceiveNotificationsView: View {
    let inputs: [NotificationViewInput]

    var body: some View {
        ForEach(items) { item in
            NotificationBanner(bannerType: item.bannerType, accessibilityIdentifier: item.accessibilityIdentifier)
        }
    }

    private var items: [NotificationBannerItem] {
        MultiWalletNotificationBannerMapper().mapItems(inputs)
    }
}
