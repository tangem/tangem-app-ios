//
//  SendDestinationAddressView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemAccessibilityIdentifiers

struct SendDestinationAddressView: View {
    @ObservedObject var viewModel: SendDestinationAddressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            title

            content
        }
        .animation(.default, value: viewModel.textViewModel.height)
    }

    @ViewBuilder
    private var title: some View {
        Group {
            switch viewModel.error {
            case .none:
                Text(Localization.sendRecipient)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            case .some(let string):
                Text(string)
                    .style(Fonts.Bold.footnote, color: Colors.Text.warning)
            }
        }
        .lineLimit(1)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 10) {
            addressIconView

            SUITextView(viewModel: viewModel.textViewModel, text: viewModel.text.asBinding, font: UIFonts.Regular.subheadline, color: UIColor.textPrimary1)

            trailingView
        }
    }

    private var addressIconView: some View {
        Circle()
            .fill(Colors.Button.secondary)
            .frame(width: 36, height: 36)
            .overlay {
                if viewModel.isValidating {
                    ProgressView()
                } else {
                    AddressIconView(viewModel: AddressIconViewModel(address: viewModel.text.value))
                }
            }
    }

    @ViewBuilder
    private var trailingView: some View {
        if viewModel.text.value.isEmpty {
            HStack(alignment: .center, spacing: 8) {
                scanQRButton

                pasteButton
            }
        } else {
            clearButton
        }
    }

    private var scanQRButton: some View {
        RoundedButton(image: Assets.Glyphs.scanQrIcon) {
            viewModel.didTapScanQRButton()
        }
    }

    private var pasteButton: some View {
        StringPasteButton(style: .custom) { string in
            viewModel.didTapPasteButton(string: string)
        }
    }

    private var clearButton: some View {
        Button {
            viewModel.didTapClearButton()
        } label: {
            Assets.clear.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
                .frame(width: 24, height: 24)
        }
    }
}
