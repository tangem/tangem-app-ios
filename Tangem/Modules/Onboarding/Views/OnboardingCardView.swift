//
//  OnboardingCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingCardView: View {
    
    enum CardType {
        case dark, light
        
        var imageName: String {
            switch self {
            case .dark: return "dark_card"
            case .light: return "light_card"
            }
        }
        
        var blankCardType: BlankCard.CardType {
            switch self {
            case .dark: return .dark
            case .light: return .light
            }
        }
    }
    
    var placeholderCardType: CardType
    var cardImage: UIImage?
    var cardScanned: Bool
    
    var body: some View {
        GeometryReader { geom in
            if let image = cardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: geom.size)
                    .opacity(cardScanned ? 1.0 : 0.0)
            }
            Image(placeholderCardType.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: geom.size)
                .opacity(cardScanned ? 0.0 : 1.0)
        }
//            BlankCard(cardType: placeholderCardType)
//                .opacity(cardScanned ? 0.0 : 1.0)
//        }
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
