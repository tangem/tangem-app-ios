//
//  SendDestinationAddressSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationAddressSummaryView: View {
    let address: String

    private var namespace: Namespace.ID?

    init(address: String) {
        self.address = address
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.sendRecipient)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .matchedGeometryEffectOptional(id: SendViewNamespaceId.addressTitle.rawValue, in: namespace)

            HStack(spacing: 12) {
                AddressIconView(viewModel: AddressIconViewModel(address: address))
                    .matchedGeometryEffectOptional(id: SendViewNamespaceId.addressIcon.rawValue, in: namespace)
                    .frame(size: CGSize(bothDimensions: 36))

                Text(address)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffectOptional(id: SendViewNamespaceId.addressText.rawValue, in: namespace)

                Assets.clear.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .opacity(0)
                    .matchedGeometryEffectOptional(id: SendViewNamespaceId.addressClearButton.rawValue, in: namespace)
            }
        }
        .padding(.vertical, 14)
    }
}

extension SendDestinationAddressSummaryView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(SendDestinationSummaryViewData(address: "1230123")) { data in
            SendDestinationAddressSummaryView(address: data.address)
        }

        GroupedSection(SendDestinationSummaryViewData(address: "0x391316d97a07027a0702c8A002c8A0C25d8470")) { data in
            SendDestinationAddressSummaryView(address: data.address)
        }

        GroupedSection(SendDestinationSummaryViewData(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470")) { data in
            SendDestinationAddressSummaryView(address: data.address)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
