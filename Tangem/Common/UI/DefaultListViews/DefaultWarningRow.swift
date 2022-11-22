//
//  DefaultWarningRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRow: View {
    let icon: Image
    let title: String
    let subtitle: String

    let action: () -> ()

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                icon
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(Colors.Background.secondary)
                    .cornerRadius(40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }
            .padding(.vertical, 16)
            .background(Colors.Background.primary)
            .contentShape(Rectangle())
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DefaultWarningRow_Preview: PreviewProvider {
    static var previews: some View {
        DefaultWarningRow(
            icon: Assets.attention,
            title: "Enable biometric authentication",
            subtitle: "Go to settings to enable biometric authentication in the Tandem App",
            action: {}
        )
    }
}
