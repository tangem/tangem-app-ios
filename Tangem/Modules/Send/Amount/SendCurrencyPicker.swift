//
//  SendCurrencyPicker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct SendCurrencyPicker: View {
    let cryptoIconURL: URL
    let cryptoCurrencyCode: String = "USDT"
    let fiatIconURL: URL
    let fiatCurrencyCode: String = "USD"

    @Binding var useFiatCalculation: Bool

    private let iconSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 0) {
            item(with: cryptoCurrencyCode, url: cryptoIconURL, iconRadius: 6, selected: !useFiatCalculation)

            item(with: fiatCurrencyCode, url: fiatIconURL, iconRadius: iconSize / 2, selected: useFiatCalculation)
        }
        .padding(2)
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(14)
    }

    @Namespace private var animation

    @ViewBuilder
    func item(with name: String, url: URL, iconRadius: CGFloat, selected: Bool) -> some View {
        ZStack {
            HStack(spacing: 6) {
                KFImage(url)
                    .resizable()
                    .frame(size: CGSize(bothDimensions: iconSize))
                    .cornerRadiusContinuous(iconRadius)

                Text(name)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }

            if selected {
//                Colors.Background.primary.matchedGeometryEffect(id: "id", in: animation)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            Group {
                if selected {
                    Colors.Background.primary
                        .matchedGeometryEffect(id: "id", in: animation)
                        .transition(.slide)
                        .cornerRadiusContinuous(12)
                }
            }
        )
    }
}

private struct PickerExample: View {
    @State private var currency = 0
    @State private var useFiatCalculation = false

    var body: some View {
        VStack {
            SendCurrencyPicker(
                cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/solana.png")!,
                fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                useFiatCalculation: $useFiatCalculation
            )
            .frame(maxWidth: 250)

            Picker("Currency", selection: $currency) {
                Text("USDT").tag(0)
                Text("USD").tag(1)
            }
            .pickerStyle(.segmented)

            Button("Toggle") {
                withAnimation(.linear(duration: 2)) {
                    useFiatCalculation.toggle()
                    currency = currency == 0 ? 1 : 0
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    PickerExample()
}

