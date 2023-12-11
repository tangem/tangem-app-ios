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
    private let font: Font

    private let toolbarButton: () -> ToolbarButton

    @State private var presentIOS17WorkaroundSheet = false

    init(
        decimalValue: Binding<DecimalNumberTextField.DecimalValue?>,
        maximumFractionDigits: Int,
        font: Font,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.font = font
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        // An experimental workaround for a buggy `.toolbar` modifier on iOS 17+,
        // see https://developer.apple.com/forums/thread/736040?answerId=774135022#774135022 for details
        if #available(iOS 17.0, *) {
            textField
                .onChange(of: isInputActive) { newValue in
                    if newValue {
                        presentIOS17WorkaroundSheet = true
                    }
                }
                .sheet(isPresented: $presentIOS17WorkaroundSheet) {
                    Color.clear
                        .onAppear { presentIOS17WorkaroundSheet = false }
                        .presentationConfiguration { sheetPresentationController in
                            let detent = UISheetPresentationController.Detent.custom(
                                identifier: .init("com.tangem.FocusedDecimalNumberTextFieldDetent")
                            ) { _ in
                                return 1.0
                            }
                            sheetPresentationController.detents = [detent]
                            sheetPresentationController.largestUndimmedDetentIdentifier = detent.identifier
                            sheetPresentationController.containerView?.alpha = .zero
                        }
                }
        } else {
            textField
        }
    }

    @ViewBuilder
    private var textField: some View {
        DecimalNumberTextField(
            decimalValue: $decimalValue,
            decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits),
            font: font
        )
        .maximumFractionDigits(maximumFractionDigits)
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
}

struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        if #available(iOS 15.0, *) {
            FocusedDecimalNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8, font: Fonts.Regular.title1) {}
        }
    }
}
