//
//  OnboardingSeedPhraseGenerateView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct OnboardingSeedPhraseGenerateView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseGenerateViewModel

    @State var wordsColumnMaxWidth: CGFloat?

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $viewModel.selectedLength, content: {
                ForEach(viewModel.availableLengths) { mnemonicLength in
                    Text(mnemonicLength.pickerTitle)
                }
            })
            .pickerStyle(.segmented)
            .padding(.horizontal, 52)

            ScrollView(.vertical, showsIndicators: false) {
                switch viewModel.selectedLength {
                case .twelveWords:
                    twelveWordsContent
                case .twentyFourWords:
                    twentyFourWordsContent
                }
            }

            MainButton(
                title: Localization.commonContinue,
                style: .primary,
                action: {
                    viewModel.continueAction()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, AppConstants.isSmallScreen ? 10 : 6)
        }
        .animation(.default, value: viewModel.selectedLength)
        .padding(.top, 20)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Text(Localization.onboardingSeedGenerateTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(viewModel.selectedLength.descriptionMessage)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 54)
        }
    }

    private var twelveWordsContent: some View {
        VStack(spacing: 24) {
            header

            HStack(alignment: .top, spacing: 8) {
                let verticalSpacing: CGFloat = 18
                let wordsHalfCount = viewModel.words.count / 2

                wordsVerticalView(indexRange: 0 ..< wordsHalfCount, verticalSpacing: verticalSpacing)

                wordsVerticalView(indexRange: wordsHalfCount ..< viewModel.words.count, verticalSpacing: verticalSpacing)
            }
            .padding(.horizontal, 48)
        }
        .padding(.top, 24)
    }

    private var twentyFourWordsContent: some View {
        VStack(spacing: 24) {
            header
                .padding(.top, 24)

            HStack(alignment: .top, spacing: 8) {
                let verticalSpacing: CGFloat = 12
                let wordsHalfCount = viewModel.words.count / 2

                wordsVerticalView(indexRange: 0 ..< wordsHalfCount, verticalSpacing: verticalSpacing)

                wordsVerticalView(indexRange: wordsHalfCount ..< viewModel.words.count, verticalSpacing: verticalSpacing)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 26)
        }
    }

    @ViewBuilder
    private func wordsVerticalView(indexRange: Range<Int>, verticalSpacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            ForEach(indexRange, id: \.self) { index in
                HStack(alignment: .center, spacing: 0) {
                    Text("\(index + 1). ") // The space character after the dot is 'U+2009 THIN SPACE'
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .fixedSize()
                        .readGeometry(\.size.width, onChange: updateWordsColumnMaxWidth(width:))
                        .frame(width: wordsColumnMaxWidth, alignment: .leading)

                    let wordView = Text("\(viewModel.words[index])")
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    // The order of the `fixedSize` modifier must be different on iOS 15 and iOS 16+,
                    // otherwise the layout will be broken
                    if #available(iOS 16.0, *) {
                        wordView
                            .screenCaptureProtection()
                            .fixedSize()
                    } else {
                        wordView
                            .fixedSize()
                            .screenCaptureProtection()
                    }

                    Spacer()
                }
            }
        }
    }

    private func updateWordsColumnMaxWidth(width: CGFloat) {
        wordsColumnMaxWidth = max(wordsColumnMaxWidth ?? .zero, width)
    }
}

struct OnboardingSeedPhraseGenerateView_Previews: PreviewProvider {
    static var seedPhraseManager: SeedPhraseManager {
        let manager = SeedPhraseManager()
        _ = try? manager.generateSeedPhrase()
        return manager
    }

    static var previews: some View {
        OnboardingSeedPhraseGenerateView(viewModel: .init(seedPhraseManager: seedPhraseManager, delegate: nil))
    }
}
