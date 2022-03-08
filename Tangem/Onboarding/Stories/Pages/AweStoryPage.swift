//
//  AweStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AweStoryPage: View {
    @Binding var progress: Double
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    private let personProgressEnd = 0.5
    private let titleProgressStart = 0.15
    private let titleProgressEnd = 0.35

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()
            
            Group {
                Text("story_awe_title")
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                
                Text("story_awe_description")
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            .modifier(AnimatableOffsetModifier(
                progress: progress,
                start: titleProgressStart,
                end: titleProgressEnd,
                curveX: { _ in
                    0
                }, curveY: {
                    40 * pow(2, -15 * $0)
                }
            ))
            .modifier(AnimatableVisibilityModifier(
                progress: progress,
                start: titleProgressStart,
                end: .infinity
            ))
            
            Spacer()
            
            Image("coin_shower")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .modifier(AnimatableScaleModifier(
                    progress: progress,
                    start: 0,
                    end: personProgressEnd) {
                        1 + pow(2, -25 * $0)
                    }
                )
            
            StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
    }
}

struct AweStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        AweStoryPage(progress: .constant(1)) { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
        .environment(\.colorScheme, .dark)
    }
}
