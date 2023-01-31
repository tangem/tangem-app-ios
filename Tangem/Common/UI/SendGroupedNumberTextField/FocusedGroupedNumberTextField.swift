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
    @Binding private var decimalValue: Decimal?
    @FocusState private var isInputActive: Bool
    private var maximumFractionDigits: Int

    private let toolbarButton: () -> ToolbarButton

    init(
        decimalValue: Binding<Decimal?>,
        maximumFractionDigits: Int,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        GroupedNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: maximumFractionDigits)
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
            // On change handler must be after onAppear for ignore automatic change isInputActive value
            .onChange(of: isInputActive) { isInputActive in
                if isInputActive {
                    Analytics.log(.swapSendTokenBalanceClicked)
                }
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
    @State private static var decimalValue: Decimal?

    static var previews: some View {
        if #available(iOS 15.0, *) {
            FocusedGroupedNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: 8) {}
        }
    }
}
