//
//  CurrenciesStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CurrenciesStoryPage: View {
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()
            
            Text("story_currencies_title")
                .font(.system(size: 36, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding()
                .padding(.top, StoriesConstants.titleExtraTopPadding)
            
            Text("story_currencies_description")
                .font(.system(size: 22))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Color.clear
                .background(
                    Image("currencies")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(x: 0, y: -40) // to combat the padding embedded into the image
                    ,
                    alignment: .top
                )
                .clipped()
                .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
                                .frame(height: geometry.size.height / 3)
                        }
                    }
                )
            
            StoriesBottomButtons(scanColorStyle: .grayAlt, orderColorStyle: .black, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CurrenciesStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        CurrenciesStoryPage { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
