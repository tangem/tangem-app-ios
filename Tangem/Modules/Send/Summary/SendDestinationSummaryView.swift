//
//  SendDestinationSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationSummaryView: View {
    let types: [SendDestinationSummaryViewType]

    var body: some View {
        GroupedSection(types) { type in
            switch type {
            case .address(let address):
                addressView(address: address)
            case .additionalField(let type, let value):
                additionalFieldView(type: type, value: value)
            }
        }
        .horizontalPadding(14)
        .separatorStyle(.minimum)
    }

    @ViewBuilder
    private func addressView(address: String) -> some View {
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

    @ViewBuilder
    private func additionalFieldView(type: SendAdditionalFields, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(type.name)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            Text(value)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    GroupedScrollView {
        SendDestinationSummaryView(
            types: [
                .address(address: "1230123"),
            ]
        )

        SendDestinationSummaryView(
            types: [
                .address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
            ]
        )

        SendDestinationSummaryView(
            types: [
                .address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                .additionalField(type: .memo, value: "123456789"),
            ]
        )

        SendDestinationSummaryView(
            types: [
                .address(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470"),
                .additionalField(type: .destinationTag, value: "123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789"),
            ]
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
