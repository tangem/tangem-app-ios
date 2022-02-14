//
//  CurrenciesStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CurrenciesStoryPage: View {
    var body: some View {
        VStack {
            Text("story_currencies_title")
                .multilineTextAlignment(.center)
            
            Text("story_currencies_description")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Spacer()
            

            Image("currencies")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Spacer()
            
            HStack {
                Text("Scan Card")
                
                Text("Order Card")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CurrenciesStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        CurrenciesStoryPage()
    }
}
