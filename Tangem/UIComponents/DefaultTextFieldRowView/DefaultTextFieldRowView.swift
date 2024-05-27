//
//  DefaultTextFieldRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DefaultTextFieldRowView: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .tint(Colors.Text.primary1)
                .labelsHidden()
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}

#Preview("DefaultTextFieldRowView") {
    struct Preview: View {
        @State var text: String = "Wallet"
        var body: some View {
            ZStack {
                Colors.Background.secondary.ignoresSafeArea()

                DefaultTextFieldRowView(title: "Name", text: $text)
                    .padding()
            }
        }
    }

    return Preview()
}
