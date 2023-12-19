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
    
    
    

   
    
    var body: some View {
        HStack(spacing: 0) {
            item(with: cryptoCurrencyCode, url: cryptoIconURL, iconRadius: 6, selected: true)

            item(with: fiatCurrencyCode, url: fiatIconURL, iconRadius: 9, selected: false)
        }
        
        .padding(2)
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(14)
    }
    
    @ViewBuilder
    func item(with name: String, url: URL, iconRadius: CGFloat, selected: Bool) -> some View {
        HStack(spacing: 6) {
            KFImage(url)
                .resizable()
                .frame(size: CGSize(bothDimensions: 18))
                .cornerRadiusContinuous(iconRadius)
            
            Text(name)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(selected ? Colors.Background.primary : .clear)
        .cornerRadiusContinuous(12)
    }
}

#Preview {
    VStack {
        SendCurrencyPicker(
            cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/solana.png")!,
            fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!
        )
        .frame(maxWidth: 250)
        
        Spacer()
        
        
        
    }
    .frame(maxWidth: .infinity)
    .background(Colors.Background.tertiary)
}
