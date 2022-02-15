//
//  AweStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AweStoryPage: View {
    var scanCard: (() -> Void)
    var orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            Text("story_awe_title")
                .font(.system(size: 36, weight: .semibold))
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
            
            HStack {
                Button {
                    scanCard()
                } label: {
                    Text("home_button_scan")
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
                
                Button {
                    orderCard()
                } label: {
                    Text("home_button_order")
                }
                .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt, layout: .flexibleWidth))
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_dark_story_background").edgesIgnoringSafeArea(.all))
    }
}

struct AweStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        AweStoryPage { } orderCard: { }
    }
}
