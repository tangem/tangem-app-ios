//
//  SendDestinationTextView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationTextView: View {
    @ObservedObject var viewModel: SendDestinationTextViewModel

    private var namespace: Namespace.ID?
    private var iconNamespaceId: String?
    private var titleNamespaceId: String?
    private var textNamespaceId: String?
    private var clearButtonNamespaceId: String?

    init(viewModel: SendDestinationTextViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedSection(viewModel) { _ in
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
                    VStack(alignment: .leading, spacing: 2) {
                        fieldName
                        input
                    }

                    pasteButton
                }
                .padding(.vertical, 10)
            }
        } footer: {
            Text(viewModel.description)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
        .innerContentPadding(2)
        .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.address.rawValue, namespace: namespace)
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var fieldName: some View {
        if let errorText = viewModel.errorText {
            Text(errorText)
                .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                .lineLimit(1)
        } else {
            Text(viewModel.name)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .matchedGeometryEffectOptional(id: titleNamespaceId, in: namespace)
        }
    }

    private var addressIconView: some View {
        AddressIconView(viewModel: AddressIconViewModel(address: viewModel.input))
            .matchedGeometryEffectOptional(id: iconNamespaceId, in: namespace)
            .frame(size: CGSize(bothDimensions: 36))
    }

    private var input: some View {
        ZStack {
            // Hidden icon to ensure the layout stays the same way
            clearIcon
                .hidden()

            HStack(spacing: 12) {
                Group {
                    if #available(iOS 16, *) {
                        TextField(viewModel.placeholder, text: $viewModel.input, axis: .vertical)
                            .lineLimit(2, reservesSpace: false)
                    } else {
                        TextField(viewModel.placeholder, text: $viewModel.input)
                    }
                }
                .disabled(viewModel.isDisabled)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .matchedGeometryEffectOptional(id: textNamespaceId, in: namespace)

                if !viewModel.input.isEmpty {
                    Button(action: viewModel.clearInput) {
                        clearIcon
                            .matchedGeometryEffectOptional(id: clearButtonNamespaceId, in: namespace)
                    }
                }
            }
        }
    }

    private var clearIcon: some View {
        Assets.clear.image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
    }

    @ViewBuilder
    private var pasteButton: some View {
        if viewModel.input.isEmpty, !viewModel.isDisabled {
            if #available(iOS 16.0, *) {
                PasteButton(payloadType: String.self) { strings in
                    guard let string = strings.first else { return }

                    // We receive the value on the non-GUI thread
                    DispatchQueue.main.async {
                        viewModel.didEnterDestination(string)
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

extension SendDestinationTextView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setIconNamespaceId(_ iconNamespaceId: String) -> Self {
        map { $0.iconNamespaceId = iconNamespaceId }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setTextNamespaceId(_ textNamespaceId: String) -> Self {
        map { $0.textNamespaceId = textNamespaceId }
    }

    func setClearButtonNamespaceId(_ clearButtonNamespaceId: String) -> Self {
        map { $0.clearButtonNamespaceId = clearButtonNamespaceId }
    }
}

#Preview {
    GroupedScrollView {
        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .address(networkName: "Ethereum"), input: .just(output: ""), isDisabled: .just(output: false), errorText: .just(output: nil), didEnterDestination: { _ in }))

        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .address(networkName: "Ethereum"), input: .just(output: "0x391316d97a07027a0702c8A002c8A0C25d8470"), isDisabled: .just(output: false), errorText: .just(output: nil), didEnterDestination: { _ in }))

        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: ""), isDisabled: .just(output: false), errorText: .just(output: nil), didEnterDestination: { _ in }))

        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: "123456789"), isDisabled: .just(output: false), errorText: .just(output: nil), didEnterDestination: { _ in }))

        Text("There are two fields and they must be aligned 👇")
            .foregroundColor(.blue)
            .font(.caption)

        // To make sure everything's aligned and doesn't jump when entering stuff
        ZStack {
            SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: ""), isDisabled: .just(output: false), errorText: .just(output: nil), didEnterDestination: { _ in }))
                .opacity(0.5)

            SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: "Optional"), isDisabled: .just(output: false), errorText: .just(output: nil), didEnterDestination: { _ in }))
                .opacity(0.5)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
