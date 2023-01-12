//
//  FocusedNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// It same as`GroupedNumberTextField` but with support focus state and toolbar buttons
@available(iOS 15.0, *)
struct FocusedNumberTextField<ToolbarButton: View>: View {
    @Binding private var decimalValue: Decimal?
    @FocusState private var isInputActive: Bool
    @State private var maximumFractionDigits: Int = 8

    private let toolbarButton: () -> ToolbarButton

    init(
        decimalValue: Binding<Decimal?>,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        GroupedNumberTextField(decimalValue: $decimalValue)
            .maximumFractionDigits(maximumFractionDigits)
            .focused($isInputActive)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    toolbarButton()

                    Button {
                        isInputActive = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .resizable()
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
extension FocusedNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }
}

struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: Decimal?

    static var previews: some View {
        if #available(iOS 15.0, *) {
            FocusedNumberTextField(decimalValue: $decimalValue) {}
        }
    }
}
