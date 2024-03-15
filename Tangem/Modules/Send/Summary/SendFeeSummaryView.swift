//
//  SendFeeSummaryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFeeSummaryView: View {
    let data: SendFeeSummaryViewData

    private var namespace: Namespace.ID?
    private var titleNamespaceId: String?
    private var textNamespaceId: String?

    init(data: SendFeeSummaryViewData) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .lineLimit(1)
                .matchedGeometryEffectOptional(id: titleNamespaceId, in: namespace)

            Text(data.text)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .matchedGeometryEffectOptional(id: textNamespaceId, in: namespace)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension SendFeeSummaryView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String?) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setTextNamespaceId(_ textNamespaceId: String?) -> Self {
        map { $0.textNamespaceId = textNamespaceId }
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(SendFeeSummaryViewData(title: "Title", text: "Text")) { data in
            SendFeeSummaryView(data: data)
        }

        GroupedSection(SendFeeSummaryViewData(title: "Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title ", text: "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text ")) { data in
            SendFeeSummaryView(data: data)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
