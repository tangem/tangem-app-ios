//
//  LearnAndEarnStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LearnAndEarnStoryPage: View {
    //    [REDACTED_USERNAME] var progress: Double
    let learn: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                StoriesTangemLogo()
                    .padding()
                
                VStack(spacing: 12) {
#warning("L10n")
                    Text("Learn and get a bonus")
                        .font(.system(size: 43, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.white)
                    
#warning("L10n")
                    Text("Complete the training, get the opportunity to buy Tangem wallet with a discount and receive 1inch tokens on your wallet")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Assets.LearnAndEarn._1inchLogoBig.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .ignoresSafeArea(edges: .bottom)
            
            #warning("L10n")
            MainButton(
                title: "Learn",
                style: .primary,
                isLoading: false,
                action: learn
            )
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
    }
}

struct LearnAndEarnStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        LearnAndEarnStoryPage {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}
