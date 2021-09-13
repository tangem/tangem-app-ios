//
//  OnboardingCardView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingCardView: View {
    
    var baseCardName: String
    var backCardImage: UIImage?
    var cardScanned: Bool
    var cardNumber: Int? = nil
    
    private let cardRotationAnimDuration: TimeInterval = 0.2
    
    var body: some View {
        ZStack(alignment: .center) {
            if let image = backCardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
//                    .background(Color.green.opacity(0.6))
                    .opacity(cardScanned ? 1.0 : 0.0)
            }
            Image(baseCardName)
                .resizable()
                .aspectRatio(contentMode: .fit)
//                .background(Color.pink.opacity(0.6))
                .opacity(cardScanned ? 0.0 : 1.0)
        }
    }
    
}

struct OnboardingCardView_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            OnboardingCardView(baseCardName: "dark_card",
                               backCardImage: nil,
                               cardScanned: false,
                               cardNumber: 1)
            OnboardingCardView(baseCardName: "light_card",
                               backCardImage: nil,
                               cardScanned: false,
                               cardNumber: 2)
            OnboardingCardView(baseCardName: "dark_card",
                               backCardImage: UIImage(named: "twin1"),
                               cardScanned: true)
            OnboardingCardView(baseCardName: "dark_card",
                               backCardImage: UIImage(named: "tangem_wallet"),
                               cardScanned: false,
                               cardNumber: 4)
            
        }
    }
    
}
