//
//  MailFallbackView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct MailFallbackView: View {
    static let preferredHeight: CGFloat = 240

    let openMailAction: () -> Void
    let shareLogsAction: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(Localization.commonContactSupport)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(MailAccessibilityIdentifiers.fallbackTitle)

                Text(Localization.emailFallbackAlertDescription)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Divider()

            Button {
                dismiss()
                openMailAction()
            } label: {
                Text(Localization.emailFallbackAlertOpenMailButton)
                    .style(Fonts.Regular.body, color: Colors.Text.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .accessibilityIdentifier(MailAccessibilityIdentifiers.fallbackOpenMailButton)

            Divider()

            Button {
                dismiss()
                shareLogsAction()
            } label: {
                Text(Localization.emailFallbackAlertShareLogsButton)
                    .style(Fonts.Regular.body, color: Colors.Text.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .accessibilityIdentifier(MailAccessibilityIdentifiers.fallbackShareLogsButton)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    MailFallbackView(openMailAction: {}, shareLogsAction: {})
}
#endif
