//
//  SUITextView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

class SUITextViewModel: ObservableObject {
    @Published var height: CGFloat = 10
    @Published var placeholder: String = Localization.sendEnterAddressField
}

struct SUITextView: View {
    @ObservedObject private var viewModel: SUITextViewModel
    @Binding private var text: String
    @State private var width: CGFloat = 10

    private let font: UIFont
    private let color: UIColor

    init(viewModel: SUITextViewModel, text: Binding<String>, font: UIFont, color: UIColor) {
        self.viewModel = viewModel
        _text = text
        self.font = font
        self.color = color
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(viewModel.placeholder)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.disabled)
                    .lineLimit(1)
            }

            UITextViewWrapper(text: $text, currentHeight: $viewModel.height, width: $width, font: font, color: color)
                .readGeometry(\.size.width, bindTo: $width)
                .frame(height: viewModel.height)
        }
    }
}
