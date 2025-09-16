//
//  WCTransactionNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct WCTransactionNotificationsView: View {
    let notifications: [NotificationViewInput]

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(notifications, id: \.id) { notification in
                NotificationView(input: notification)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: notifications.count)
    }
}
