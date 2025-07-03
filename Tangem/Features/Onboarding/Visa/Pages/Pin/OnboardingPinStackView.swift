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
    let isDisabled: Bool

    @Binding var pinText: String

    @Environment(\.pinStackColor) private var pinColor
    @Environment(\.pinStackSecured) private var pinSecured

    @State private var firstResponder: Bool? = true

    var body: some View {
        ZStack {
            backgroundField
                .opacity(0)

            HStack(spacing: 12) {
                ForEach(0 ..< maxDigits, id: \.self) { index in
                    Text(getDigit(index))
                        .style(Fonts.Regular.title1, color: pinColor)
                        .frame(width: 42, height: 58)
                        .background(Colors.Field.primary)
                        .cornerRadius(14)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                setFirstResponser(true)
            }
        }
        .onAppear {
            setFirstResponser(true)
        }
    }

    @ViewBuilder
    private var backgroundField: some View {
        CustomTextField(
            text: $pinText,
            isResponder: $firstResponder,
            actionButtonTapped: Binding.constant(false),
            handleKeyboard: true,
            keyboard: .numberPad,
            placeholder: "",
            maxCount: maxDigits
        )
        .setAutocapitalizationType(.none)
        .disabled(isDisabled)
    }

    private func getDigit(_ index: Int) -> String {
        let pin = Array(pinText)

        if pin.indices.contains(index), !String(pin[index]).isEmpty {
            return pinSecured ? AppConstants.dotSign : String(pin[index])
        }

        return ""
    }

    private func setFirstResponser(_ value: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            firstResponder = value
        }
    }
}

private struct PinStackColorKey: EnvironmentKey {
    static let defaultValue: Color = Colors.Text.primary1
}

private struct PinStackSecuredKey: EnvironmentKey {
    static let defaultValue: Bool = false
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
}

extension View {
    func pinStackColor(_ color: Color) -> some View {
        environment(\.pinStackColor, color)
    }

    func pinStackSecured(_ isSecured: Bool) -> some View {
        environment(\.pinStackSecured, isSecured)
    }
}

struct OnboardingPinStackView_Previews: PreviewProvider {
    @State static var pinText: String = ""

    static var previews: some View {
        OnboardingPinStackView(maxDigits: 4, isDisabled: false, pinText: $pinText)
    }
}
