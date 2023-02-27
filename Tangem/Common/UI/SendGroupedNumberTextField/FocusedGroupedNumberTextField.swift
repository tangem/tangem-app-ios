//
//  FocusedGroupedNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// It same as`GroupedNumberTextField` but with support focus state and toolbar buttons
@available(iOS 15.0, *)
struct FocusedGroupedNumberTextField<ToolbarButton: View>: View {
    @Binding private var decimalValue: GroupedNumberTextField.DecimalValue?
    @FocusState private var isInputActive: Bool
    private var maximumFractionDigits: Int

    private let toolbarButton: () -> ToolbarButton

    init(
        decimalValue: Binding<GroupedNumberTextField.DecimalValue?>,
        maximumFractionDigits: Int,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        GroupedNumberTextField(
            decimalValue: $decimalValue,
            groupedNumberFormatter: GroupedNumberFormatter(maximumFractionDigits: maximumFractionDigits)
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
extension FocusedGroupedNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }
}

struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: GroupedNumberTextField.DecimalValue?

    static var previews: some View {
        if #available(iOS 15.0, *) {
            FocusedGroupedNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8) {}
        }
    }
}
