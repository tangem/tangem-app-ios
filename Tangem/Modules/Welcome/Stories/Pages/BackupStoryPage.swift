//
//  BackupStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackupStoryPage: View {
    @Binding var progress: Double
    let isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 14) {
                Text(Localization.storyBackupTitle)
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)

                Group {
                    Text(Localization.storyBackupDescription1) + Text(" ") +
                        Text(Localization.storyBackupDescription2Bold).bold() + Text(" ") + Text(Localization.storyBackupDescription3)
                }
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            GeometryReader { geometry in
                Color.clear
                    .background(
                        // Bottom card
                        Image("wallet_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.7 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(-40 + 10 * progress),
                                axis: (0.2 + progress / 3, 0.1 + progress / 3, 0.4 + progress / 3),
                                perspective: 0
                            )
                            .offset(x: 0.25 * geometry.size.width, y: 0.3 * geometry.size.width)
                            .offset(x: -30 * progress, y: -30 * progress)
                            .scaleEffect(1 + 0.2 * progress)
                    )
                    .background(
                        // Top left
                        Image("wallet_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.65 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(50 - progress * 15),
                                axis: (0.15 + progress / 4, 0.3 + progress / 4, 0.4 + progress / 4),
                                perspective: 0
                            )
                            .offset(x: -0.45 * geometry.size.width, y: -0.2 * geometry.size.width)
                            .offset(x: 20 * progress, y: 10 * progress)
                    )
                    .background(
                        // Top right
                        Image("wallet_card")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.5 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(50 + 20 * progress),
                                axis: (0.3 + progress / 9, 0.0 + progress / 9, -0.5 + progress / 9),
                                perspective: 0
                            )
                            .offset(x: 0.3 * geometry.size.width, y: -0.3 * geometry.size.width)
                            .offset(x: -10 * progress, y: -5 * progress)
                            .scaleEffect(1 - 0.2 * progress)
                    )
            }

            Spacer()

            StoriesBottomButtons(scanColorStyle: .secondary, orderColorStyle: .primary, isScanning: isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BackupStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        BackupStoryPage(progress: .constant(1), isScanning: false) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
