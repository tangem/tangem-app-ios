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
                    .modifier(FadeModifier(
                        progress: progress,
                        start: Double(index) / Double(words.count) * wordListProgressEnd,
                        end: Double(index+1) / Double(words.count) * wordListProgressEnd
                    ))
            }

            VStack(spacing: 0) {
                StoriesTangemLogo()
                    .padding()
                    .modifier(FadeModifier(progress: progress, start: wordListProgressEnd, end: .infinity))
    
                Text("story_meet_title")
                    .font(.system(size: 60, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                    .modifier(FadeModifier(progress: progress, start: titleProgressStart, end: .infinity))
                    .offset(x: 0, y: 40 * pow(2, -15 * normalizeTitleProgress(progress)))

                Color.clear
                    .background(
                        Image("hand_with_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .fixedSize(horizontal: false, vertical: true)
                            .edgesIgnoringSafeArea(.bottom)
                            .scaleEffect((1 + pow(2, -25 * normalizeCardHandProgress(progress))))
                            .modifier(FadeModifier(progress: progress, start: wordListProgressEnd, end: 1))
                        ,
                        alignment: .top
                    )
            }
            
            VStack {
                Spacer()
            
                StoriesBottomButtons(scanColorStyle: .black, orderColorStyle: .grayAlt, scanCard: scanCard, orderCard: orderCard)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .modifier(FadeModifier(
                progress: progress,
                start: immediatelyShowButtons ? 0 : wordListProgressEnd,
                end: .infinity
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_dark_story_background").edgesIgnoringSafeArea(.all))
    }
    
    private func normalizeCardHandProgress(_ progress: Double) -> Double {
        normalizeProgress(progress: progress, start: wordListProgressEnd, end: 1)
    }
    
    private func normalizeTitleProgress(_ progress: Double) -> Double {
        normalizeProgress(progress: progress, start: titleProgressStart, end: titleProgressEnd)
    }
    
    private func normalizeProgress(progress: Double, start: Double, end: Double) -> Double {
        let value = (progress - start) / (end - start)
        return max(0, min(value, 1))
    }
}


fileprivate struct FadeModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity((start <= progress && progress < end) ? 1 : 0)
    }
}


struct MeetTangemStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        MeetTangemStoryPage(progress: .constant(0.8), immediatelyShowButtons: false) { } orderCard: { }
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
