//  OnboardingPinStackView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct OnboardingPinStackView: View {
    let maxDigits: Int
    var handleKeyboard: Bool = true
    let isDisabled: Bool

    @Binding var pinText: String

    @Environment(\.pinStackColor) private var pinColor
    @Environment(\.pinStackSecured) private var pinSecured
    @Environment(\.pinStackDigitBackground) private var pinDigitBackground

    @State private var isResponder: Bool? = false

    var body: some View {
        ZStack {
            backgroundField
                .opacity(0)

            HStack(spacing: 12) {
                ForEach(0 ..< maxDigits, id: \.self) { index in
                    Text(getDigit(index))
                        .style(Fonts.Regular.title1, color: pinColor)
                        .frame(width: 42, height: 58)
                        .background(pinDigitBackground)
                        .cornerRadius(14)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isResponder = !isDisabled
            }
        }
        .screenCaptureProtection()
        .fixedSize()
        .onChange(of: isDisabled) { disabled in
            isResponder = !disabled
        }
        .onDidAppear {
            isResponder = !isDisabled
        }
        .onWillDisappear {
            isResponder = false
        }
    }

    @ViewBuilder
    private var backgroundField: some View {
        CustomTextField(
            text: $pinText,
            isResponder: $isResponder,
            actionButtonTapped: Binding.constant(false),
            handleKeyboard: handleKeyboard,
            keyboard: .numberPad,
            placeholder: "",
            maxCount: maxDigits
        )
        .setAutocapitalizationType(.none)
    }

    private func getDigit(_ index: Int) -> String {
        let pin = Array(pinText)

        if pin.indices.contains(index), !String(pin[index]).isEmpty {
            return pinSecured ? AppConstants.dotSign : String(pin[index])
        }

        return ""
    }
}

private struct PinStackColorKey: EnvironmentKey {
    static let defaultValue: Color = Colors.Text.primary1
}

private struct PinStackSecuredKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct PinStackDigitBackground: EnvironmentKey {
    static let defaultValue: Color = Colors.Field.primary
}

extension EnvironmentValues {
    var pinStackColor: Color {
        get { self[PinStackColorKey.self] }
        set { self[PinStackColorKey.self] = newValue }
    }

    var pinStackSecured: Bool {
        get { self[PinStackSecuredKey.self] }
        set { self[PinStackSecuredKey.self] = newValue }
    }

    var pinStackDigitBackground: Color {
        get { self[PinStackDigitBackground.self] }
        set { self[PinStackDigitBackground.self] = newValue }
    }
}

extension View {
    func pinStackColor(_ color: Color) -> some View {
        environment(\.pinStackColor, color)
    }

    func pinStackSecured(_ isSecured: Bool) -> some View {
        environment(\.pinStackSecured, isSecured)
    }

    func pinStackDigitBackground(_ color: Color) -> some View {
        environment(\.pinStackDigitBackground, color)
    }
}

struct OnboardingPinStackView_Previews: PreviewProvider {
    @State static var pinText: String = ""

    static var previews: some View {
        OnboardingPinStackView(maxDigits: 4, isDisabled: false, pinText: $pinText)
    }
}
