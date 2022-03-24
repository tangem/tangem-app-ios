//
//  CurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

struct CurrencyView: View {
    @ObservedObject var model: CurrencyViewModel
    var subtitle: LocalizedStringKey = "currency_subtitle_expanded"

    var body: some View {
        HStack(alignment: .customTop, spacing: 14) {
            Icon(model.imageURL, name: model.name)
                .alignmentGuide(.customTop, computeValue: { d in d[VerticalAlignment.top] - 1.5 })
               
            VStack(spacing: 26) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        HStack(spacing: 4) {
                            Text(model.name)
                                .foregroundColor(.tangemGrayDark6)
                            Text(symbolFormatted)
                                .foregroundColor(Color(hex: "#A9A9AD")!)
                        }
                        .lineLimit(1)
                        .fixedSize()
                        .font(.system(size: 17, weight: .medium, design: .default))

                        if isExpanded {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#A9A9AD")!)
                        } else {
                            HStack(spacing: 5) {
                                ForEach(model.items) {
                                    CurrencyItemView(model: $0).icon
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        isExpanded.toggle()
                    } label: {
                        chevronView
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if isExpanded {
                    VStack(spacing: 18) {
                        ForEach(model.items) { CurrencyItemView(model: $0) }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .animation(nil) //Disable animations on scroll reuse
    }
    
    private var symbolFormatted: String {"(\(model.symbol))"}
    @State private var isExpanded = false
    
    private var chevronView: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 17, weight: .medium, design: .default))
            .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
            .foregroundColor(Color(hex: "#CCCCCC")!)
            .padding(.vertical, 4)
    }
}

fileprivate struct Icon: View {
    let url: URL?
    let name: String
    var size: CGSize = .init(width: 46, height: 46)
    
    var body: some View {
        KFImage(url)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .placeholder { CircleImageTextView(name: name, color: .tangemGrayLight4) }
            .fade(duration: 0.3)
            .forceTransition()
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
            .frame(size: size)
    }
    
    init(_ url: URL?, name: String) {
        self.url = url
        self.name = name
    }
}

struct CurrencyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatefulPreviewWrapper(false) {
                CurrencyView(model: CurrencyViewModel(imageURL: nil,
                                                      name: "Tether",
                                                      symbol: "USDT",
                                                      items: [
                                                        CurrencyItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                                              isReadOnly: false,
                                                                              isDisabled: false,
                                                                              isSelected: $0),
                                                        CurrencyItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                                              isReadOnly: false,
                                                                              isDisabled: false,
                                                                              isSelected: $0)
                                                      ]))
            }
            Spacer()
        }
    }
}
