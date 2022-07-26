//
//  DefaultToggleRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultToggleRowView: View {
    let title: String
    let isOn: Binding<Bool>

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(Colors.Text.primary1)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyleCompat(Colors.Control.checked)
                .disabled(true) // [REDACTED_TODO_COMMENT]
        }
    }
}
