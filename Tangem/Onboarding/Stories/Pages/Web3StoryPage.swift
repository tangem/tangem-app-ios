//
//  Web3StoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct Web3StoryPage: View {
    @Binding var progress: Double
    let isScanning: Bool
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    private let numberOfRows = 6
    private let numberOfRowImages = 6
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()
            
            VStack(spacing: 16) {
                Text("story_web3_title")
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)
                
                Text("story_web3_description")
                    .font(.system(size: 20))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Color.clear
                .background(
                    VStack {
                        Group {
                            ForEach(0..<numberOfRows) { index in
                                let odd = (index % 2 == 0)
                                Image("dapps-\(index % numberOfRowImages)")
                                    .offset(x: odd ? 50 : 0)
                                    .offset(x: -75 * Double(numberOfRows - index) / Double(numberOfRows) * progress, y: 0)
                            }
                        }
                        .frame(height: 63)
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
                                .frame(height: geometry.size.height / 4)
                        }
                    }
                )
            
            StoriesBottomButtons(scanColorStyle: .grayAlt2, orderColorStyle: .black, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Web3StoryPage_Previews: PreviewProvider {
    static var previews: some View {
        Web3StoryPage(progress: .constant(1), isScanning: false) { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
