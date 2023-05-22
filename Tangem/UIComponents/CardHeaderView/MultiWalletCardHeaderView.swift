//
//  MultiWalletCardHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletCardHeaderView: View {
    @ObservedObject var viewModel: MultiWalletCardHeaderViewModel

    private let imageSize: CGSize = .init(width: 120, height: 106)
    private let horizontalSpacing: CGFloat = 6

    private var balanceTextTrailingOffset: CGFloat {
        if viewModel.isWithCardImage {
            return imageSize.width + horizontalSpacing
        }

        return 0
    }

    private func balanceTextWidth(containerWidth: CGFloat) -> CGFloat {
        containerWidth - balanceTextTrailingOffset
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.cardName)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Text(viewModel.balance)
                        .multilineTextAlignment(.leading)
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .skeletonable(isShown: viewModel.isLoadingBalance, size: .init(width: 102, height: 24), radius: 6)
                        .showSensitiveInformation(true)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .frame(width: balanceTextWidth(containerWidth: proxy.size.width), height: 34, alignment: .leading)

                    HStack(spacing: 6) {
                        Text(viewModel.numberOfCardsText)

                        if viewModel.isWalletImported {
                            Text("•")

                            Text(Localization.commonSeedPhrase)
                        }
                    }
                    .style(Fonts.Regular.caption2, color: Colors.Text.disabled)
                    .fixedSize()
                }
                .padding(.vertical, 12)

                if let cardImage = viewModel.cardImage {
                    Spacer()
                        .frame(minWidth: horizontalSpacing)

                    cardImage.image
                        .frame(size: imageSize)
                }
            }
        }
        .frame(height: imageSize.height)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

struct CardHeaderView_Previews: PreviewProvider {
    struct CardHeaderPreview: View {
        @ObservedObject var provider: FakeCardHeaderPreviewProvider = .init()

        var body: some View {
            ZStack {
                Color.gray

                VStack(spacing: 16) {
                    ForEach(
                        provider.models.indices,
                        id: \.self,
                        content: { index in
                            MultiWalletCardHeaderView(viewModel: provider.models[index])
                                .onTapGesture {
                                    let provider = provider.infoProviders[index]
                                    provider.tapAction(provider)
                                }
                        }
                    )
                }
            }
        }
    }

    static var previews: some View {
        CardHeaderPreview()
            .background(Colors.Background.secondary)
    }
}
