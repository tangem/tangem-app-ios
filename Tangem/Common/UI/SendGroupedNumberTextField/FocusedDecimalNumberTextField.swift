//
//  FocusedDecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// It same as`DecimalNumberTextField` but with support focus state / toolbar buttons / suffix
struct FocusedDecimalNumberTextField<ToolbarButton: View>: View {
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?
    @FocusState private var isInputActive: Bool
    @State private var textFieldSize: CGSize = .zero
    private let toolbarButton: () -> ToolbarButton

    private var initialFocusBehavior: InitialFocusBehavior = .immediateFocus
    private var onFocusChanged: ((Bool) -> Void)?
    private var maximumFractionDigits: Int
    private var placeholderColor: Color = Colors.Text.disabled
    private var textColor: Color = Colors.Text.primary1
    private var font: Font = Fonts.Regular.title1
    private var alignment: Alignment = .leading
    private var suffix: String? = nil
    private var suffixColor: Color {
        switch decimalValue {
        case .none:
            return placeholderColor
        case .some:
            return textColor
        }
    }

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
        ZStack(alignment: alignment) {
            HStack(alignment: .center, spacing: 8) {
                textField

                if let suffix {
                    Text(suffix)
                        .style(font, color: suffixColor)
                        .onTapGesture {
                            isInputActive = true
                        }
                }
            }
            .readGeometry(\.frame.size, bindTo: $textFieldSize)

            // Expand the tappable area
            Color.clear
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .frame(height: textFieldSize.height)
                .onTapGesture {
                    isInputActive = true
                }
        }
        .lineLimit(1)
        .onChange(of: isInputActive) { isInputActive in
            onFocusChanged?(isInputActive)
        }
    }

    @ViewBuilder
    private var textField: some View {
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
            guard let focusDelayDuration = initialFocusBehavior.delayDuration else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + focusDelayDuration) {
                isInputActive = true
            }
        }
    }
}

// MARK: - Setupable

extension FocusedDecimalNumberTextField: Setupable {
    func onFocusChanged(_ action: ((Bool) -> Void)?) -> Self {
        map { $0.onFocusChanged = action }
    }

    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }

    func font(_ font: Font) -> Self {
        map { $0.font = font }
    }

    func suffix(_ suffix: String?) -> Self {
        map { $0.suffix = suffix }
    }

    func alignment(_ alignment: Alignment) -> Self {
        map { $0.alignment = alignment }
    }

    func initialFocusBehavior(_ initialFocusBehavior: InitialFocusBehavior) -> Self {
        map { $0.initialFocusBehavior = initialFocusBehavior }
    }
}

struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        StatefulPreviewWrapper(decimalValue) { decimalValue in
            FocusedDecimalNumberTextField(decimalValue: decimalValue, maximumFractionDigits: 8) {}
                .suffix("USDT")
                .alignment(.center)
                .padding()
                .background(Colors.Background.action)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Colors.Background.tertiary)
    }
}
