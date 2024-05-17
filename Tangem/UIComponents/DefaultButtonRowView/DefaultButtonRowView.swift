//
//  DefaultButtonRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DefaultButtonRowView: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .style(Fonts.Regular.callout, color: Colors.Text.accent)
        }
        .buttonStyle(.plain)
        .infinityFrame(axis: .horizontal)
    }
}
