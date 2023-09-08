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
    var immediatelyShowTangemLogo: Bool
    var immediatelyShowButtons: Bool
    let useWallet2Image: Bool
    @Binding var isScanning: Bool
    let didReachWalletImage: () -> Void
    let scanCard: () -> Void
    let orderCard: () -> Void

    private let words: [String] = [
        "",
        "",
        Localization.storyMeetBuy,
        Localization.storyMeetStore,
        Localization.storyMeetSend,
        Localization.storyMeetPay,
        // Localization.storyMeetExchange,
        Localization.storyMeetBorrow,
        Localization.storyMeetLend,
        Localization.storyMeetLend,
        // Duplicate the last word to make it last longer
        // Localization.commonStake, // no stake for now
        "",
    ]

    private let wordListProgressEnd = 0.6

    private let titleProgressStart = 0.7
    private let titleProgressEnd = 0.9

    var body: some View {
        ZStack {
            ForEach(0 ..< words.count, id: \.self) { index in
                Text(words[index])
                    .foregroundColor(.white)
                    .font(.system(size: 60, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                    .modifier(AnimatableVisibilityModifier(
                        progress: progress,
                        start: Double(index) / Double(words.count) * wordListProgressEnd,
                        end: Double(index + 1) / Double(words.count) * wordListProgressEnd
                    ))
            }

            VStack(spacing: 0) {
                StoriesTangemLogo()
                    .padding()
                    .modifier(AnimatableVisibilityModifier(
                        progress: progress,
                        start: immediatelyShowTangemLogo ? 0 : wordListProgressEnd,
                        end: .infinity
                    ))

                Text(Localization.storyMeetTitle)
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
                        handWithCardImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .fixedSize(horizontal: false, vertical: true)
                            .edgesIgnoringSafeArea(.bottom)
                            .overlay(
                                LinearGradient(stops: [
                                    Gradient.Stop(color: Color("tangem_story_background").opacity(0), location: 0.7),
                                    Gradient.Stop(color: Color("tangem_story_background"), location: 1),
                                ], startPoint: .top, endPoint: .bottom)
                                    .frame(minWidth: 1000)
                            )
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
                            .modifier(ProgressCheckerModifier(
                                progress: progress,
                                threshold: wordListProgressEnd
                            ))
                            .onPreferenceChange(ProgressCheckerModifier.PreferenceKey.self) { finishedShowingWordList in
                                if finishedShowingWordList {
                                    didReachWalletImage()
                                }
                            },

                        alignment: .top
                    )
            }

            VStack {
                Spacer()

                StoriesBottomButtons(scanColorStyle: .primary, orderColorStyle: .secondary, isScanning: $isScanning, scanCard: scanCard, orderCard: orderCard)
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

    private var handWithCardImage: Image {
        if useWallet2Image {
            return Assets.Stories.handWithCard.image
        } else {
            return Assets.Stories.handWithCardOld.image
        }
    }
}

struct MeetTangemStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        MeetTangemStoryPage(progress: .constant(0.8), immediatelyShowTangemLogo: false, immediatelyShowButtons: false, useWallet2Image: true, isScanning: .constant(false)) {} scanCard: {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}

private struct ProgressCheckerModifier: AnimatableModifier {
    enum PreferenceKey: SwiftUI.PreferenceKey {
        static var defaultValue: Bool { false }

        static func reduce(value: inout Bool, nextValue: () -> Bool) {
            value = nextValue()
        }
    }

    var progress: Double
    let threshold: Double

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var reachedThreshold: Bool {
        return progress >= threshold
    }

    func body(content: Content) -> some View {
        content
            .preference(key: PreferenceKey.self, value: reachedThreshold)
    }
}
