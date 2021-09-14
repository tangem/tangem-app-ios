//
//  OnboardingCardView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingCardView: View {
    
    var placeholderCardType: BlankCard.CardType
    var cardImage: UIImage?
    var cardScanned: Bool
    
    private let cardRotationAnimDuration: TimeInterval = 0.2
    
    var body: some View {
        ZStack(alignment: .center) {
            if let image = cardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(cardScanned ? 1.0 : 0.0)
            }
            BlankCard(cardType: placeholderCardType)
                .opacity(cardScanned ? 0.0 : 1.0)
        }
    }
    
}

struct OnboardingCardView_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            OnboardingCardView(placeholderCardType: .dark,
                               cardImage: nil,
                               cardScanned: false)
            OnboardingCardView(placeholderCardType: .light,
                               cardImage: nil,
                               cardScanned: false)
            OnboardingCardView(placeholderCardType: .dark,
                               cardImage: UIImage(named: "twin1"),
                               cardScanned: true)
            OnboardingCardView(placeholderCardType: .dark,
                               cardImage: UIImage(named: "tangem_wallet"),
                               cardScanned: false)
            
        }
    }
    
}
