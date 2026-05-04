//
//  MainHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers
import TangemLocalization

struct MainHeaderView: View {
    @ObservedObject var viewModel: MainHeaderViewModel

    @ScaledMetric private var heightScaled = Size.height

    @ScaledMetric private var titleStubWidthScaled = Size.titleStub.width
    @ScaledMetric private var titleStubHeightScaled = Size.titleStub.height

    @ScaledMetric private var subtitleStubWidthScaled = Size.subtitleStub.width
    @ScaledMetric private var subtitleStubHeightScaled = Size.subtitleStub.height

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.userWalletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer(minLength: 6)

            if viewModel.isUserWalletLocked {
                Colors.Field.primary
                    .frame(width: titleStubWidthScaled, height: titleStubHeightScaled)
                    .cornerRadiusContinuous(6)
                    .padding(.vertical, 5)
            } else {
                LoadableBalanceView(
                    state: viewModel.balance,
                    style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                    loader: .init(size: CGSize(width: titleStubWidthScaled, height: titleStubHeightScaled), cornerRadius: 6),
                    accessibilityIdentifier: MainAccessibilityIdentifiers.totalBalance
                )
            }

            Spacer(minLength: 10)

            MainHeaderSubtitleView(
                subtitleViewState: viewModel.subtitleViewState,
                subtitleInfo: viewModel.subtitleInfo,
                subtitleContainsSensitiveInfo: viewModel.subtitleContainsSensitiveInfo,
                isUserWalletLocked: viewModel.isUserWalletLocked,
                isLoadingSubtitle: viewModel.isLoadingSubtitle,
                subtitleStubWidthScaled: subtitleStubWidthScaled,
                subtitleStubHeightScaled: subtitleStubHeightScaled
            )
        }
        .lineLimit(1)
        .padding(.vertical, 12)
        .background(alignment: .bottom) {
            HStack {
                Spacer(minLength: 6)

                // A transparent 1px image is used to preserve the structural identity of the view,
                // otherwise visual glitches may ocurr during the header swipe animation
                //
                // Do not replace nil coalescing operator here with any kind of operators
                // that breaks the view's structural identity (`if`, `switch`, etc)
                (viewModel.cardImage ?? Assets.clearColor1px)
                    .image
                    .frame(width: Size.cardImage.width, height: Size.cardImage.height)
                    .accessibilityIdentifier(MainAccessibilityIdentifiers.headerCardImage)
            }
            .hidden(viewModel.cardImage == nil)
        }
        .padding(.horizontal, 14)
        .frame(height: heightScaled)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(Size.cornerRadius)
        .previewContentShape(cornerRadius: Size.cornerRadius)
    }
}

extension MainHeaderView {
    private enum Size {
        static let height: CGFloat = 106

        static let cardImage = CGSize(width: 120, height: Self.height)
        static let titleStub = CGSize(width: 102, height: 24)
        static let subtitleStub = CGSize(width: 52, height: 12)

        static let cornerRadius: CGFloat = 14
    }
}

struct CardHeaderView_Previews: PreviewProvider {
    struct CardHeaderPreview: View {
        @ObservedObject var provider: FakeCardHeaderPreviewProvider = .init()

        var body: some View {
            ZStack {
                Colors.Background.secondary
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ForEach(
                        provider.models.indices,
                        id: \.self,
                        content: { index in
                            MainHeaderView(viewModel: provider.models[index])
                                .onTapGesture {
                                    let provider = provider.infoProviders[index]
                                    provider.tapAction(provider)
                                }
                        }
                    )
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        CardHeaderPreview()
    }
}
