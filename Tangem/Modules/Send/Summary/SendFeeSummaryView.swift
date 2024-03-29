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
    private var optionNamespaceId: String?
    private var amountNamespaceId: String?

    init(data: SendFeeSummaryViewData) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .lineLimit(1)
                .matchedGeometryEffectOptional(id: titleNamespaceId, in: namespace)

            HStack(spacing: 0) {
                feeOption
                    .matchedGeometryEffectOptional(id: optionNamespaceId, in: namespace)

                Spacer()

                feeAmount
                    .matchedGeometryEffectOptional(id: amountNamespaceId, in: namespace)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var feeOption: some View {
        HStack(spacing: 8) {
            data.feeIconImage
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundColor(Colors.Icon.accent)

            Text(data.feeName)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var feeAmount: some View {
        HStack(spacing: 4) {
            Text(data.cryptoAmount)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)
                .layoutPriority(1)

            if let fiatAmount = data.fiatAmount {
                Text("•")
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                    .layoutPriority(3)

                Text(fiatAmount)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .layoutPriority(2)
            }
        }
    }
}

extension SendFeeSummaryView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String?) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setOptionNamespaceId(_ optionNamespaceId: String?) -> Self {
        map { $0.optionNamespaceId = optionNamespaceId }
    }

    func setAmountNamespaceId(_ amountNamespaceId: String?) -> Self {
        map { $0.amountNamespaceId = amountNamespaceId }
    }
}

#Preview {
    GroupedScrollView(spacing: 14) {
        GroupedSection(SendFeeSummaryViewData(title: "Network fee", feeOption: .market, cryptoAmount: "0.159817 MATIC", fiatAmount: "0,22 $")) { data in
            SendFeeSummaryView(data: data)
        }

        GroupedSection(SendFeeSummaryViewData(title: "Network Fee Network Fee Network Fee Network Fee Network Fee Network Fee Network Fee Network Fee", feeOption: .slow, cryptoAmount: "159 817 159 817.159817 MATIC", fiatAmount: "100 120,22 $")) { data in
            SendFeeSummaryView(data: data)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
