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
/// - `Suffix`
/// - Different `Alignment`
struct SendDecimalNumberTextField: View {
    // Public
    @ObservedObject private var viewModel: DecimalNumberTextField.ViewModel

    // Internal state
    @FocusState private var isInputActive: Bool
    @State private var textFieldHeight: CGFloat = .zero
    @State private var oneSpaceWidth: CGFloat = .zero

    // Setupable
    private var initialFocusBehavior: InitialFocusBehavior = .noFocus
    private var toolbarType: ToolbarType?
    private var appearance: DecimalNumberTextField.Appearance = .init()
    private var alignment: Alignment = .leading
    private var onFocusChanged: ((Bool) -> Void)?

    private var prefixSuffixOptions = PrefixSuffixOptions()

    private var prefixSuffixColor: Color {
        switch viewModel.value {
        case .none:
            return appearance.placeholderColor
        case .some:
            return appearance.textColor
        }
    }

    init(viewModel: DecimalNumberTextField.ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: alignment) {
            HStack(alignment: .center, spacing: 0) {
                prefixSuffixView(prefixSuffixOptions.prefix, hasSpaceAfterText: prefixSuffixOptions.hasSpaceAfterPrefix)

                textField

                prefixSuffixView(prefixSuffixOptions.suffix, hasSpaceBeforeText: prefixSuffixOptions.hasSpaceBeforeSuffix)
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
        DecimalNumberTextField(viewModel: viewModel)
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
                guard !isInputActive,
                      let focusDelayDuration = initialFocusBehavior.delayDuration else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + focusDelayDuration) {
                    isInputActive = true
                }
            }
            .onChange(of: isInputActive) { isInputActive in
                onFocusChanged?(isInputActive)
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
    private func prefixSuffixView(_ text: String?, hasSpaceBeforeText: Bool = false, hasSpaceAfterText: Bool = false) -> some View {
        if let text {
            if hasSpaceBeforeText {
                FixedSpacer(width: oneSpaceWidth)
            }

            Text(text)
                .style(appearance.font, color: prefixSuffixColor)
                .onTapGesture {
                    isInputActive = true
                }
                .background(
                    Text(" ")
                        .font(appearance.font)
                        .readGeometry(\.frame.size.width, bindTo: $oneSpaceWidth)
                )

            if hasSpaceAfterText {
                FixedSpacer(width: oneSpaceWidth)
            }
        }
    }
}

// MARK: - Setupable

extension SendDecimalNumberTextField: Setupable {
    func toolbarType(_ toolbarType: ToolbarType?) -> Self {
        map { $0.toolbarType = toolbarType }
    }

    func prefixSuffixOptions(_ prefixSuffixOptions: PrefixSuffixOptions) -> Self {
        map { $0.prefixSuffixOptions = prefixSuffixOptions }
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

    func onFocusChanged(_ action: ((Bool) -> Void)?) -> Self {
        map { $0.onFocusChanged = action }
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
                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .prefixSuffixOptions(.init(suffix: "WEI", hasSpaceBeforeSuffix: true))
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .prefixSuffixOptions(.init(suffix: "USDT", hasSpaceBeforeSuffix: true))
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .prefixSuffixOptions(.init(suffix: "WEI", hasSpaceBeforeSuffix: true))
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
