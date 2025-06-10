//
//  OnboardingCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct OnboardingCardView: View {
    enum CardType {
        case dark
        case light

        var imageType: ImageType {
            switch self {
            case .dark: return Assets.Onboarding.darkCard
            case .light: return Assets.Onboarding.lightCard
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
    var cardImage: Image?
    var cardScanned: Bool

    var body: some View {
        GeometryReader { geom in
            if let image = cardImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: geom.size)
                    .opacity(cardScanned ? 1.0 : 0.0)
            } else {
                placeholderCardType.imageType.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: geom.size)
                    .opacity(cardScanned ? 0.0 : 1.0)
                    .transition(.opacity.animation(.easeOut.delay(0.3)))
            }
        }
    }
}

struct OnboardingCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OnboardingCardView(
                placeholderCardType: .dark,
                cardImage: nil,
                cardScanned: false
            )
            OnboardingCardView(
                placeholderCardType: .light,
                cardImage: nil,
                cardScanned: false
            )
        }
    }
}
