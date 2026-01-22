//
//  CurrenciesStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct CurrenciesStoryPage: View {
    var progress: Double
    var isScanning: Bool
    let createWallet: () -> Void
    let scanCard: () -> Void
    let orderCard: () -> Void
    let searchTokens: () -> Void
    let scanTroubleshootingDialog: Binding<ConfirmationDialogViewModel?>

    private let isMobileWalletEnabled = FeatureProvider.isAvailable(.mobileWallet)

    private let numberOfRows = 6
    private let rowImages = [
        Assets.Stories.currency0,
        Assets.Stories.currency1,
        Assets.Stories.currency2,
        Assets.Stories.currency3,
        Assets.Stories.currency4,
    ]

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 16) {
                Text(Localization.storyCurrenciesTitle)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)

                Text(Localization.storyCurrenciesDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .bottom) {
                Color.clear
                    .background(
                        VStack {
                            Group {
                                ForEach(0 ..< numberOfRows, id: \.self) { index in
                                    rowView(forIndex: index)
                                }
                            }
                            .frame(height: 80)
                        }
                        .offset(x: 0, y: 30),

                        alignment: .top
                    )
                    .clipped()
                    .overlay(
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                LinearGradient(colors: [.clear, Colors.Old.tangemStoryBackground], startPoint: .top, endPoint: .bottom)
                                    .frame(height: geometry.size.height / 3)
                            }
                        }
                    )

                if !isMobileWalletEnabled {
                    MainButton(
                        title: Localization.commonSearchTokens,
                        icon: .leading(Assets.search),
                        style: .secondary,
                        isDisabled: isScanning,
                        action: searchTokens
                    )
                    .padding(.horizontal, 16)
                }
            }

            StoriesBottomButtons(
                isScanning: isScanning,
                createWallet: createWallet,
                scanCard: scanCard,
                orderCard: orderCard,
                scanTroubleShootingDialog: scanTroubleshootingDialog
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(Colors.Old.tangemStoryBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rowView(forIndex index: Int) -> some View {
        let isOdd = (index % 2 == 0)
        let assetIndex = index % rowImages.count
        let asset = rowImages[assetIndex]

        return asset.image
            .offset(x: isOdd ? 50 : 0)
            .offset(x: -75 * Double(numberOfRows - index) / Double(numberOfRows) * progress)
    }
}

struct CurrenciesStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        CurrenciesStoryPage(
            progress: 1,
            isScanning: false,
            createWallet: {},
            scanCard: {},
            orderCard: {},
            searchTokens: {},
            scanTroubleshootingDialog: .constant(nil)
        )
        .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
