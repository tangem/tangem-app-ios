//
//  FinishStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct FinishStoryPage: View {
    var body: some View {
        VStack {
            Text("story_finish_title")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("story_finish_description")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Spacer()
            
            
            Image(systemName: "person")
                .foregroundColor(.white)
            
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

struct FinishStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        FinishStoryPage()
    }
}
