//
//  MeetTangemStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct MeetTangemStoryPage: View {
    var body: some View {
        VStack {
            Text("story_meet_title")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Spacer()
            
            Image("hand_with_card")
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

struct MeetTangemStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        MeetTangemStoryPage()
    }
}
