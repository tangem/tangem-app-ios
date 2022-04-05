//
//  MeetTangemStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct MeetTangemStoryPage: View {
    @Binding var progress: Double
    var immediatelyShowButtons: Bool
    let isScanning: Bool
    let scanCard: (() -> Void)
    let orderCard: (() -> Void)
    
    private let words: [LocalizedStringKey] = [
        "",
        "",
        "story_meet_buy",
        "story_meet_store",
        "story_meet_send",
        "story_meet_pay",
        "story_meet_exchange",
        "story_meet_borrow",
        "story_meet_lend",
        "story_meet_lend",
        // Duplicate the last word to make it last longer
//        "story_meet_stake", // no stake for now
        "",
    ]
    
    private let wordListProgressEnd = 0.6
    
    private let titleProgressStart = 0.7
    private let titleProgressEnd = 0.9
    
    var body: some View {
        ZStack {
            ForEach(0..<words.count) { index in
                Text(words[index])
                    .foregroundColor(.white)
                    .font(.system(size: 60, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                    .modifier(AnimatableVisibilityModifier(
                        progress: progress,
                        start: Double(index) / Double(words.count) * wordListProgressEnd,
                        end: Double(index+1) / Double(words.count) * wordListProgressEnd
                    ))
            }
            
            VStack(spacing: 0) {
                StoriesTangemLogo()
                    .padding()
                    .modifier(AnimatableVisibilityModifier(
                        progress: progress,
                        start: wordListProgressEnd,
                        end: .infinity
                    ))
                
                Text("story_meet_title")
                    .font(.system(size: 60, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                    .padding(.bottom, 10)
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
                
                Color.clear
                    .background(
                        Image("hand_with_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .fixedSize(horizontal: false, vertical: true)
                            .edgesIgnoringSafeArea(.bottom)
                            .storyImageAppearanceModifier(
                                progress: progress,
                                start: wordListProgressEnd,
                                fastMovementStartCoefficient: 1.1,
                                fastMovementSpeedCoefficient: -25,
                                fastMovementEnd: 0.25,
                                slowMovementSpeedCoefficient: 0.1
                            )
                            .modifier(AnimatableVisibilityModifier(
                                progress: progress,
                                start: wordListProgressEnd,
                                end: 1
                            ))
                        ,
                        alignment: .top
                    )
            }
            
            VStack {
                Spacer()
                
                StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .modifier(AnimatableVisibilityModifier(
                progress: progress,
                start: immediatelyShowButtons ? 0 : wordListProgressEnd,
                end: .infinity
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
    }
}


struct MeetTangemStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        MeetTangemStoryPage(progress: .constant(0.8), immediatelyShowButtons: false, isScanning: false) { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
        .environment(\.colorScheme, .dark)
    }
}
