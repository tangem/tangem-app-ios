//
//  SendNewDestinationAdditionalFieldView.swift
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

struct SendNewDestinationAdditionalFieldView: View {
    @ObservedObject var viewModel: SendNewDestinationAdditionalFieldViewModel
    let namespace: SendDestinationView.Namespace

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                title

                textField
            }

            if !viewModel.disabled {
                trailingView
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        Group {
            switch viewModel.error {
            case .none:
                Text(viewModel.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            case .some(let string):
                Text(string)
                    .style(Fonts.Bold.footnote, color: Colors.Text.warning)
            }
        }
        .lineLimit(1)
        .matchedGeometryEffect(id: namespace.names.addressAdditionalFieldTitle, in: namespace.id)
    }

    private var textField: some View {
        TextField(viewModel.placeholder, text: $viewModel.text)
            .autocorrectionDisabled()
            .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            .disabled(viewModel.disabled)
            .matchedGeometryEffect(id: namespace.names.addressAdditionalFieldText, in: namespace.id)
    }

    @ViewBuilder
    private var trailingView: some View {
        if viewModel.text.isEmpty {
            pasteButton
        } else {
            clearButton
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
        .matchedGeometryEffect(id: namespace.names.addressAdditionalFieldClearButton, in: namespace.id)
    }
}
