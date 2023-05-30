//
//  LearnAndEarnStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LearnAndEarnStoryPage: View {
    let learn: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    StoriesTangemLogo()
                        .padding()

                    VStack(spacing: 12) {
                        Text(Localization.storyLearnTitle)
                            .font(.system(size: 43, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white)

                        Text(Localization.storyLearnDescription)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Assets.LearnAndEarn.oneInchLogoBig.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }

                MainButton(
                    title: Localization.storyLearnLearn,
                    style: .primary,
                    isLoading: false,
                    action: learn
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                OneInchBlueGradientView(radius: geometry.size.width)
                    .frame(width: 10_000, height: 10_000)
                    .offset(x: -geometry.size.width / 2, y: -geometry.size.height / 6)
            )
            .background(
                OneInchRedGradientView(radius: geometry.size.width)
                    .frame(width: 10_000, height: 10_000)
                    .offset(x: geometry.size.width / 2, y: geometry.size.height / 4)
            )
            .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
        }
    }
}

struct LearnAndEarnStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        LearnAndEarnStoryPage {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}
