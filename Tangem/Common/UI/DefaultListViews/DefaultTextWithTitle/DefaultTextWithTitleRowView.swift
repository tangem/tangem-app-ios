//
//  DefaultTextWithTitleRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultTextWithTitleRowView: View {
//    let namespace: Namespace.ID

    let data: DefaultTextWithTitleRowViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .lineLimit(1)

            Text(data.text)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
//                .matchedGeometryEffect(id: SendViewNamespaceId.feeText, in: namespace)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(DefaultTextWithTitleRowViewData(title: "Title", text: "Text")) { data in
            DefaultTextWithTitleRowView(data: data)
        }

        GroupedSection(DefaultTextWithTitleRowViewData(title: "Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title ", text: "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text ")) { data in
            DefaultTextWithTitleRowView(data: data)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
