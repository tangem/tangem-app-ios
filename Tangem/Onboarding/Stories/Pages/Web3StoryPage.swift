//
//  Web3StoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct Web3StoryPage: View {
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            Text("story_web3_title")
                .font(.system(size: 36, weight: .semibold))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("story_web3_description")
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Color.clear
                .background(
                    Image("dapps")
                        .scaleEffect(0.9, anchor: .top)
                        .offset(x: 50, y: 0)
                    ,
                    alignment: .top
                )
                .clipped()
                .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
                                .frame(height: geometry.size.height / 4)
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

struct Web3StoryPage_Previews: PreviewProvider {
    static var previews: some View {
        Web3StoryPage { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
