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
                    .frame(width: 24, height: 24)
                    .padding(9)
                    .background(Colors.Background.secondary)
                    .cornerRadius(40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.medium)
                        .foregroundColor(Colors.Text.primary1)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(Colors.Text.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(16)
        .background(Colors.Background.primary)
        .contentShape(Rectangle())
        .cornerRadius(12)
    }
}
