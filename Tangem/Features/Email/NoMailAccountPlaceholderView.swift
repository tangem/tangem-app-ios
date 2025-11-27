//
//  NoMailAccountPlaceholderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemLocalization

struct NoMailAccountPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(Localization.commonClose, action: dismiss.callAsFunction)
                Spacer()
            }
            .padding([.horizontal, .top])

            Spacer()

            Text(Localization.mailErrorNoAccountsTitle)
                .font(.title)
                .accessibilityIdentifier(MailAccessibilityIdentifiers.noAccountsTitle)

            Text(Localization.mailErrorNoAccountsBody)
                .font(.body)
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

#Preview {
    NoMailAccountPlaceholderView()
}
