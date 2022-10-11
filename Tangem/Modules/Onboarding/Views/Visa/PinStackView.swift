//
//  PinStackView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct PinStackView: View {
    var maxDigits: Int = 4

    @Binding var pinText: String

    @State private var pinInput: String = ""

    var body: some View {
        ZStack {
            backgroundField
                .opacity(0)

            HStack(spacing: 12) {
                ForEach(0 ..< maxDigits, id: \.self) { index in
                    Text(getDigit(index))
                        .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                        .frame(width: 42, height: 58)
                        .background(Colors.Field.primary)
                        .cornerRadius(14)
                }
            }
        }
    }

    @ViewBuilder
    private var backgroundField: some View {
        let binding = Binding<String> {
            return pinInput
        } set: { value in
            pinInput = value
            pinText = value
        }

        CustomTextField(text: binding,
                        isResponder: Binding.constant(true),
                        actionButtonTapped: Binding.constant(true),
                        keyboard: .numberPad,
                        placeholder: "",
                        maxCount: maxDigits)
    }

    private func getDigit(_ index: Int) -> String {
        let pin = Array(pinInput)

        if pin.indices.contains(index), !String(pin[index]).isEmpty {
            return String(pin[index])
        }

        return ""
    }
}

struct PinStackView_Previews: PreviewProvider {
    @State static var pinText: String = ""

    static var previews: some View {
        PinStackView(pinText: $pinText)
    }
}
