//
//  SendDestinationInputView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationInputView: View {
    let viewModel: SendDestinationInputViewModel

    var body: some View {
        GroupedSection(viewModel) { _ in
            Group {
                if viewModel.showAddressIcon {
                    VStack(alignment: .leading, spacing: 14) {
                        fieldName

                        HStack(spacing: 12) {
                            addressIconView
                            input
                            pasteButton
                        }
                    }
                    .padding(.vertical, 12)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            fieldName
                            input
                        }

                        pasteButton
                    }
                    .padding(.vertical, 12)
                }
            }
        } footer: {
            Text(viewModel.description)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
        .horizontalPadding(14)
        .onAppear {
            viewModel.onAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)) { _ in
                viewModel.onBecomingActive()
        }
    }

    private var fieldName: some View {
        Text(viewModel.name)
            .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
    }

    private var addressIconView: some View {
        AddressIconView(viewModel: AddressIconViewModel(address: viewModel.input.wrappedValue))
            .frame(size: CGSize(bothDimensions: 36))
    }

    private var input: some View {
        HStack {
            TextField(viewModel.placeholder, text: viewModel.input)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            if !viewModel.input.wrappedValue.isEmpty {
                Button(action: viewModel.clearInput) {
                    Assets.clear.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                }
            }
        }
    }

    @ViewBuilder
    private var pasteButton: some View {
        if viewModel.input.wrappedValue.isEmpty {
            if #available(iOS 16.0, *) {
                PasteButton(payloadType: String.self) { strings in
                    DispatchQueue.main.async {
                        viewModel.didPasteAddress(strings)
                    }
                }
                .tint(Color.black)
                .labelStyle(.titleOnly)
                .buttonBorderShape(.capsule)
            } else {
                Button(action: viewModel.didTapLegacyPasteButton) {
                    Text(Localization.commonPaste)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(viewModel.hasTextInClipboard ? Colors.Button.primary : Colors.Button.disabled)
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.hasTextInClipboard)
            }
        }
    }
}

#Preview {
    GroupedScrollView {
        SendDestinationInputView(viewModel: SendDestinationInputViewModel(name: "Recipient", input: .constant(""), showAddressIcon: true, placeholder: "Enter address", description: "Description", didPasteAddress: { _ in }))

        SendDestinationInputView(viewModel: SendDestinationInputViewModel(name: "Recipient", input: .constant("0x391316d97a07027a0702c8A002c8A0C25d8470"), showAddressIcon: true, placeholder: "Enter address", description: "Description", didPasteAddress: { _ in }))

        SendDestinationInputView(viewModel: SendDestinationInputViewModel(name: "Memo", input: .constant(""), showAddressIcon: false, placeholder: "Optional", description: "Description", didPasteAddress: { _ in }))

        SendDestinationInputView(viewModel: SendDestinationInputViewModel(name: "Memo", input: .constant("123456789"), showAddressIcon: false, placeholder: "Optional", description: "Description", didPasteAddress: { _ in }))
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
