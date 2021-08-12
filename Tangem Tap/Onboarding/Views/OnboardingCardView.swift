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
    
    private let cardRotationAnimDuration: TimeInterval = 0.2
    
    var body: some View {
        ZStack {
            if let image = backCardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(cardScanned ? 1.0 : 0.0)
            }
            Image(baseCardName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(cardScanned ? 0.0 : 1.0)
        }
    }
    
}
