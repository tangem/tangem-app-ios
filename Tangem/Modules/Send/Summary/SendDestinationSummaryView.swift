//
//  SendDestinationSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct SendDestinationAddressSummaryView: View {
    let address: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Localization.sendRecipient)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            HStack(spacing: 12) {
                AddressIconView(viewModel: AddressIconViewModel(address: address))
                    .frame(size: CGSize(bothDimensions: 36))

                Text(address)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(SendDestinationSummaryViewType.address(address: "1230123")) { type in
            switch type {
            case .address(let address):
                SendDestinationAddressSummaryView(address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }

        GroupedSection(SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470")) { type in
            switch type {
            case .address(let address):
                SendDestinationAddressSummaryView(address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }

        GroupedSection(
            [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                SendDestinationSummaryViewType.additionalField(type: .memo, value: "123456789"),
            ]
        ) { type in
            switch type {
            case .address(let address):
                SendDestinationAddressSummaryView(address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }
        .backgroundColor(Colors.Button.disabled)

        GroupedSection(
            [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470"),
                SendDestinationSummaryViewType.additionalField(type: .destinationTag, value: "123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789"),
            ]
        ) { type in
            switch type {
            case .address(let address):
                SendDestinationAddressSummaryView(address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
