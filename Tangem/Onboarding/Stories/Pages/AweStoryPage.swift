//
//  AweStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AweStoryPage: View {
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
            
            Spacer()
            
            HStack {
                Text("Scan Card")
                
                Text("Order Card")
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct AweStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        AweStoryPage()
    }
}
