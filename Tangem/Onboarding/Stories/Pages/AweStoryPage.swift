//
//  AweStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AweStoryPage: View {
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()
            
            Text("story_awe_title")
                .font(.system(size: 36, weight: .semibold))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
            
            Text("story_awe_description")
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
            Image("coin_shower")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
    }
}

struct AweStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        AweStoryPage { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
        .environment(\.colorScheme, .dark)
    }
}
