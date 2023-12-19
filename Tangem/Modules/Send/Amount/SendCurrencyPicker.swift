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

// WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP

struct SendCurrencyPicker: View {
    let cryptoIconURL: URL
    let cryptoCurrencyCode: String = "USDT"
    let cryptoColor: Color
    
    let fiatIconURL: URL
    let fiatCurrencyCode: String = "USD"
    let fiatColor: Color
    
    @Binding var useFiatCalculation: Bool
    
    private let iconSize: CGFloat = 18
    
    // Can't use buttons because that interferes with the drag gesture
    var body: some View {
        HStack(spacing: 0) {
                item(with: cryptoCurrencyCode, url: cryptoIconURL, color: cryptoColor, iconRadius: 6)
                .onTapGesture {
                    useFiatCalculation = false
                }

                item(with: fiatCurrencyCode, url: fiatIconURL, color: fiatColor, iconRadius: iconSize / 2)
//                .onTapGesture {
//                    useFiatCalculation = true
//                }
        }
        .background(
            GeometryReader { reader in
                Color.white
                    .frame(width: reader.size.width / 2, height: reader.size.height)
                    .cornerRadius(12)
                    .offset(x: useFiatCalculation ? reader.size.width / 2 : 0)
                    .animation(.easeOut(duration: 0.25), value: useFiatCalculation)
                
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ v in
                                print("changed", v)
                                
                                if v.location.x > reader.size.width / 2 {
                                    useFiatCalculation = true
                                } else {
                                    useFiatCalculation = false
                                }
                            })
                            .onEnded({ v in
                                print("ended", v)
                                if abs(v.startLocation.x - v.location.x) > 10 {
                                        return
                                }
                                
//                                useFiatCalculation = true
                            
                            })
                        
                    )
                    .shadow(radius: 30, x: 0.0, y: 30)
            }
        )
        .padding(2)
        .background(Color(hue: 0, saturation: 0, brightness: 0.95))
        .cornerRadius(14)
        
    }
    
    @ViewBuilder
    func item(with name: String, url: URL, color: Color, iconRadius: CGFloat) -> some View {
        ZStack {
            HStack(spacing: 6) {
//                AsyncImage(url: url)
                color
                //                    .resizable()
                    .frame(width: iconSize, height: iconSize, alignment: .center)
                    .cornerRadius(iconRadius)
                
                Text(name)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
//        .contentShape(Rectangle())
    }
}

 struct PickerExample: View {
    @State private var currency = 0
    @State private var useFiatCalculation = false
    
    var body: some View {
        VStack {
            SendCurrencyPicker(
                cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/solana.png")!,
                cryptoColor: .red,
                fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                fiatColor: .blue,
                useFiatCalculation: $useFiatCalculation
            )
//            .frame(maxWidth: 250)
            
            Picker("Currency", selection: $useFiatCalculation) {
                Text("USDT").tag(false)
                Text("USD").tag(true)
            }
            .pickerStyle(.segmented)
            
            Button("Toggle") {
                useFiatCalculation.toggle()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}
extension AnyTransition {
    static var backslide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading))}
}
#Preview {
    PickerExample()
}
