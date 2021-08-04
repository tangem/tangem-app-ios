//
//  RotatingCardView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct RotatingCardView: View {
    
    var baseCardName: String
    var backCardImage: UIImage
    var cardScanned: Bool
    
    private let cardRotationAnimDuration: TimeInterval = 0.2
    
    var body: some View {
        ZStack {
            Image("card_btc")
                .resizable()
                .rotation3DEffect(
                    .init(degrees: cardScanned ? 0 : 90),
                    axis: (x: 1.0, y: 0.0, z: 0.0)
                )
                .animation(.linear(duration: cardRotationAnimDuration).delay(cardScanned ? cardRotationAnimDuration : 0))
            Image("card_twin")
                .resizable()
                .rotation3DEffect(
                    .init(degrees: cardScanned ? -90 : 0),
                    axis: (x: 1.0, y: 0.0, z: 0.0)
                )
                .animation(.linear(duration: cardRotationAnimDuration).delay(cardScanned ? 0 : cardRotationAnimDuration))
        }
    }
    
}
