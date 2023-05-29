//
//  LearnAndEarnStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

#warning("[REDACTED_TODO_COMMENT]")
fileprivate struct OneInchGradientView: View {
    let startColorName: String
    let endColorName: String
    let radius: Double

    var body: some View {
        RadialGradient(
            colors: [Color(startColorName).opacity(0.9), Color(endColorName).opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

struct OneInchBlueGradientView: View {
    let radius: Double

    var body: some View {
        OneInchGradientView(startColorName: "OneInchBlueGradientStart", endColorName: "OneInchBlueGradientStop", radius: radius)
    }
}

struct OneInchRedGradientView: View {
    let radius: Double

    var body: some View {
        OneInchGradientView(startColorName: "OneInchRedGradientStart", endColorName: "OneInchRedGradientStop", radius: radius)
    }
}

struct LearnAndEarnStoryPage: View {
    let learn: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    StoriesTangemLogo()
                        .padding()

                    VStack(spacing: 12) {
                        #warning("L10n")
                        Text("Learn and get a bonus")
                            .font(.system(size: 43, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white)

                        #warning("L10n")
                        Text("Complete the training, get the opportunity to buy Tangem wallet with a discount and receive 1inch tokens on your wallet")
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

                #warning("L10n")
                MainButton(
                    title: "Learn",
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
