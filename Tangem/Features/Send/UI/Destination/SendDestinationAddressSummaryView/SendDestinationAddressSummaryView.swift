//
//  SendDestinationAddressSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct SendDestinationAddressSummaryView: View {
    @ObservedObject var addressTextViewHeightModel: AddressTextViewHeightModel
    let address: String

    init(addressTextViewHeightModel: AddressTextViewHeightModel, address: String) {
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.address = address
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localization.sendRecipient)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            HStack(spacing: 12) {
                AddressIconView(viewModel: AddressIconViewModel(address: address))
                    .frame(size: CGSize(bothDimensions: 36))
                    .padding(.vertical, 10)

                AddressTextView(
                    heightModel: addressTextViewHeightModel,
                    text: .constant(address),
                    placeholder: "",
                    font: UIFonts.Regular.subheadline,
                    color: .textPrimary1
                )
                .disabled(true)
                .padding(.vertical, 8)

                Assets.clear.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .opacity(0)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(SendDestinationSummaryViewType.address(address: "1230123", corners: .allCorners)) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }

        GroupedSection(SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", corners: .allCorners)) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }

        GroupedSection(
            [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", corners: [.topLeft, .topRight]),
                SendDestinationSummaryViewType.additionalField(type: .memo, value: "123456789"),
            ]
        ) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }
        .backgroundColor(Colors.Button.disabled)

        GroupedSection(
            [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470", corners: [.topLeft, .topRight]),
                SendDestinationSummaryViewType.additionalField(type: .destinationTag, value: "123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789"),
            ]
        ) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
