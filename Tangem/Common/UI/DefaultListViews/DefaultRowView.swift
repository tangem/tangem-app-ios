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
    let action: (() -> Void)?

    private var isTappable: Bool { action != nil }

    /// - Parameters:
    ///   - title: Leading one line title
    ///   - details: Trailing one line text
    ///   - action: If the `action` is set that the row will be tappable and have chevron icon
    init(
        title: String,
        details: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.details = details
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
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
