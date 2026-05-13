//
//  AllowNotificationsBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct AllowNotificationsBannerView: View {
    let openSettingsAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                icon

                VStack(alignment: .leading, spacing: 4) {
                    Text(NotificationSettingsViewModel.Constants.allowNotificationsTitle)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(NotificationSettingsViewModel.Constants.allowNotificationsDescription)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: openSettingsAction) {
                Text(NotificationSettingsViewModel.Constants.allowNotificationsButton)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Colors.Button.secondary)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(Colors.Text.warning.opacity(0.1))
                .frame(width: 36, height: 36)

            Assets.attention.image
                .resizable()
                .frame(width: 20, height: 20)
        }
    }
}

// MARK: - Previews

#if DEBUG
struct AllowNotificationsBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary
                .ignoresSafeArea()

            AllowNotificationsBannerView(openSettingsAction: {})
                .padding(16)
        }
    }
}
#endif // DEBUG
