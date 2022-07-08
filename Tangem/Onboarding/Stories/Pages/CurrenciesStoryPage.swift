//
//  CurrenciesStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CurrenciesStoryPage: View {
    @Binding var progress: Double
    let isScanning: Bool
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    let searchTokens: (() -> Void)
    
    private let numberOfRows = 6
    private let numberOfRowImages = 5
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()
            
            VStack(spacing: 16) {
                Text("story_currencies_title")
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)
                
                Text("story_currencies_description")
                    .font(.system(size: 22))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            ZStack(alignment: .bottom) {
                Color.clear
                    .background(
                        VStack {
                            Group {
                                ForEach(0..<numberOfRows) { index in
                                    let odd = (index % 2 == 0)
                                    Image("currency-\(index % numberOfRowImages)")
                                        .offset(x: odd ? 50 : 0, y: 0)
                                        .offset(x: -75 * Double(numberOfRows - index) / Double(numberOfRows) * progress, y: 0)
                                }
                            }
                            .frame(height: 80)
                        }
                            .offset(x: 0, y: 30)
                        ,
                        alignment: .top
                    )
                    .clipped()
                    .overlay(
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                LinearGradient(colors: [.white.opacity(0), Color("tangem_story_background")], startPoint: .top, endPoint: .bottom)
                                    .frame(height: geometry.size.height / 3)
                            }
                        }
                    )
                
                TangemButton(title: "home_button_search_tokens", systemImage: "magnifyingglass", action: searchTokens)
                    .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt2, layout: .flexibleWidth))
                    .padding(.horizontal)
            }
            
            StoriesBottomButtons(scanColorStyle: .grayAlt2, orderColorStyle: .black, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CurrenciesStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        CurrenciesStoryPage(progress: .constant(1), isScanning: false) { } orderCard: { } searchTokens: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
