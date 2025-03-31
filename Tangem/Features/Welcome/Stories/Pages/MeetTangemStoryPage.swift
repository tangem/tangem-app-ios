//
//  MeetTangemStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct MeetTangemStoryPage: View {
    var progress: Double
    var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            Spacer()

            Text(Localization.storyMeetTitle)
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(Colors.Text.primary1)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .minorDelay)
                .padding(.horizontal, 28)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: .infinity)

            Color.clear
                .background(
                    Assets.Stories.tangemBox.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(y: -40),
                    alignment: .top
                )

            Spacer(minLength: 150)

            StoriesBottomButtons(
                scanColorStyle: .primary,
                orderColorStyle: .secondary,
                isScanning: isScanning,
                scanCard: scanCard,
                orderCard: orderCard
            )
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Old.tangemStoryBackground.edgesIgnoringSafeArea(.all))
    }
}

struct MeetTangemStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        MeetTangemStoryPage(progress: 0.8, isScanning: false) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}
