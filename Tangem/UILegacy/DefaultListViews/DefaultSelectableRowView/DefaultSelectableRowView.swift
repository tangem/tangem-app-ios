//
//  DefaultSelectableRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct DefaultSelectableRowView<ID: Hashable>: View {
    private let data: DefaultSelectableRowViewModel<ID>
    private let selection: Binding<ID>

    init(data: DefaultSelectableRowViewModel<ID>, selection: Binding<ID>) {
        self.data = data
        self.selection = selection
    }

    var body: some View {
        Button(action: { selection.isActive(compare: data.id).toggle() }) {
            HStack(alignment: .center, spacing: 12) {
                if let iconURL = data.iconURL {
                    IconView(url: iconURL, size: CGSize(bothDimensions: 24), forceKingfisher: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(data.title)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)
                        .multilineTextAlignment(.leading)

                    if let subtitle = data.subtitle {
                        Text(subtitle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 12)

                CheckIconView(isSelected: selection.isActive(compare: data.id).wrappedValue)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selection = 1

    let data = DefaultSelectableRowViewModel(
        id: 1,
        title: "Long Tap",
        subtitle: Date().timeIntervalSince1970.description
    )

    DefaultSelectableRowView(data: data, selection: $selection)
        .padding()
}
