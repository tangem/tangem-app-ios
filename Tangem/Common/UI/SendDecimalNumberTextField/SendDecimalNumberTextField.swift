//
//  SendDecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// Same as `DecimalNumberTextField` with  support
/// - `InitialFocusBehavior`
/// - `ToolbarType`
/// - Different `Alignment`
struct SendDecimalNumberTextField: View {
    // Public
    @ObservedObject private var stateObject: DecimalNumberTextField.StateObject

    // Internal state
    @FocusState private var isInputActive: Bool
    @State private var textFieldHeight: CGFloat = .zero
    @State private var oneSpaceWidth: CGFloat = .zero

    // Setupable
    private var initialFocusBehavior: InitialFocusBehavior = .noFocus
    private var toolbarType: ToolbarType?
    private var appearance: DecimalNumberTextField.Appearance = .init()
    private var alignment: Alignment = .leading

    // Suffix properties
    private var suffix: String? = nil
    private var suffixColor: Color {
        switch stateObject.value {
        case .none:
            return appearance.placeholderColor
        case .some:
            return appearance.textColor
        }
    }

    init(stateObject: DecimalNumberTextField.StateObject) {
        self.stateObject = stateObject
    }

    var body: some View {
        ZStack(alignment: alignment) {
            HStack(alignment: .center, spacing: oneSpaceWidth) {
                textField

                suffixView
            }
            .readGeometry(\.frame.size.height, bindTo: $textFieldHeight)

            // Expand the tappable area
            Color.clear
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .frame(height: textFieldHeight)
                .onTapGesture {
                    isInputActive = true
                }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var textField: some View {
        DecimalNumberTextField(stateObject: stateObject)
            .appearance(appearance)
            .focused($isInputActive)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    leadingToolbarView

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

    @ViewBuilder
    private var leadingToolbarView: some View {
        switch toolbarType {
        case .none:
            EmptyView()
        case .maxAmount(let action):
            Button(action: action) {
                Text(Localization.sendMaxAmountLabel)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)
            }
        }
    }

    @ViewBuilder
    private var suffixView: some View {
        if let suffix {
            Text(suffix)
                .style(appearance.font, color: suffixColor)
                .onTapGesture {
                    isInputActive = true
                }
                .background(
                    Text(" ")
                        .font(appearance.font)
                        .readGeometry(\.frame.size.width, bindTo: $oneSpaceWidth)
                )
        }
    }
}

// MARK: - Setupable

extension SendDecimalNumberTextField: Setupable {
    func toolbarType(_ toolbarType: ToolbarType?) -> Self {
        map { $0.toolbarType = toolbarType }
    }

    func suffix(_ suffix: String?) -> Self {
        map { $0.suffix = suffix }
    }

    func appearance(_ appearance: DecimalNumberTextField.Appearance) -> Self {
        map { $0.appearance = appearance }
    }

    func alignment(_ alignment: Alignment) -> Self {
        map { $0.alignment = alignment }
    }

    func initialFocusBehavior(_ initialFocusBehavior: InitialFocusBehavior) -> Self {
        map { $0.initialFocusBehavior = initialFocusBehavior }
    }
}

extension SendDecimalNumberTextField {
    enum ToolbarType {
        case maxAmount(action: () -> Void)
    }

    enum InitialFocusBehavior {
        case noFocus
        case immediateFocus
        case delayedFocus(duration: TimeInterval)

        var delayDuration: TimeInterval? {
            switch self {
            case .noFocus:
                nil
            case .immediateFocus:
                0
            case .delayedFocus(let duration):
                duration
            }
        }
    }
}

struct SendDecimalNumberTextField_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                SendDecimalNumberTextField(stateObject: .init(maximumFractionDigits: 8))
                    .suffix("WEI")
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(stateObject: .init(maximumFractionDigits: 8))
                    .suffix(nil)
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(stateObject: .init(maximumFractionDigits: 8))
                    .suffix("USDT")
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(stateObject: .init(maximumFractionDigits: 8))
                    .suffix("USDT")
                    .appearance(.init(font: Fonts.Regular.body))
                    .alignment(.leading)
                    .padding()
                    .background(Colors.Background.action)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}
