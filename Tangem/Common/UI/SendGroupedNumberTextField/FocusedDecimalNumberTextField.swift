//
//  FocusedDecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// It same as`DecimalNumberTextField` but with support focus state and toolbar buttons
@available(iOS 15.0, *)
struct FocusedDecimalNumberTextField<ToolbarButton: View>: View {
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?
    @FocusState private var isInputActive: Bool
    private var maximumFractionDigits: Int
    private var font: Font = Fonts.Regular.title1
    private let toolbarButton: () -> ToolbarButton

    init(
        decimalValue: Binding<DecimalNumberTextField.DecimalValue?>,
        maximumFractionDigits: Int,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        DecimalNumberTextField(
            decimalValue: $decimalValue,
            decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits)
        )
        .maximumFractionDigits(maximumFractionDigits)
        .font(font)
        .focused($isInputActive)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                toolbarButton()

                Spacer()

                Button {
                    isInputActive = false
                } label: {
                    Assets.hideKeyboard.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.primary1)
                }
            }
        }
        .onAppear {
            isInputActive = true
        }
    }
}

// MARK: - Setupable

@available(iOS 15.0, *)
extension FocusedDecimalNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }

    func isInputActive(_ active: Bool) -> Self {
        map { $0.isInputActive = active }
    }

    func font(_ font: Font) -> Self {
        map { $0.font = font }
    }
}

@available(iOS 15.0, *)
struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        StatefulPreviewWrapper(decimalValue) { decimalValue in
            FocusedDecimalNumberTextField(decimalValue: decimalValue, maximumFractionDigits: 8) {}
        }
        .padding()
        .border(Color.purple)
    }
}
