//
//  DefaultRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultRowView: View {
    let title: String
    let details: String?
    let isTappable: Bool
    let action: () -> Void

    init(
        title: String,
        details: String? = nil,
        isTappable: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.details = details
        self.isTappable = isTappable
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(Colors.Text.primary1)

                Spacer()

                if let details = details {
                    Text(details)
                        .font(.body)
                        .foregroundColor(Colors.Text.tertiary)
                        .layoutPriority(1)
                }

                if isTappable {
                    Assets.chevron
                }
            }
            .lineLimit(1)
        }
        .disabled(!isTappable)
    }
}
