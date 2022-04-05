//
//  FinishStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct FinishStoryPage: View {
    @Binding var progress: Double
    let isScanning: Bool
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()
            
            VStack(spacing: 18) {
                Text("story_finish_title")
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .minorDelay)
                
                Text("story_finish_description")
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .minorDelay)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Image("amazement")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .storyImageAppearanceModifier(
                    progress: progress,
                    start: 0,
                    fastMovementStartCoefficient: 1,
                    fastMovementSpeedCoefficient: -45,
                    fastMovementEnd: 0.15,
                    slowMovementSpeedCoefficient: 0.15
                )
            
            Spacer()
            
            StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
    }
}

struct FinishStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        FinishStoryPage(progress: .constant(1), isScanning: false) { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
        .environment(\.colorScheme, .dark)
    }
}
