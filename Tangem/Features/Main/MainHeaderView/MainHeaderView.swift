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

struct MainHeaderView: View {
    @ObservedObject var viewModel: MainHeaderViewModel

    private let imageSize: CGSize = .init(width: 120, height: 106)
    private let cornerRadius = 14.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.userWalletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()
                .frame(height: 6)

            if viewModel.isUserWalletLocked {
                Colors.Field.primary
                    .frame(width: 102, height: 24)
                    .cornerRadiusContinuous(6)
                    .padding(.vertical, 5)
            } else {
                LoadableTokenBalanceView(
                    state: viewModel.balance,
                    style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                    loader: .init(size: .init(width: 102, height: 24), cornerRadius: 6),
                    accessibilityIdentifier: MainAccessibilityIdentifiers.totalBalance
                )
            }

            Spacer()
                .frame(height: 10)

            HStack {
                subtitleText

                Spacer()
            }
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
                    .frame(size: imageSize)
                    .accessibilityIdentifier(MainAccessibilityIdentifiers.headerCardImage)
            }
            .hidden(viewModel.cardImage == nil)
        }
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(cornerRadius)
        .previewContentShape(cornerRadius: cornerRadius)
        .frame(minHeight: imageSize.height)
    }

    private var subtitleText: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.subtitleInfo.messages, id: \.self) { message in
                if viewModel.subtitleContainsSensitiveInfo {
                    SensitiveText(message)
                } else {
                    Text(message)
                }

                if message != viewModel.subtitleInfo.messages.last {
                    SubtitleSeparator()
                }
            }
        }
        .style(
            viewModel.subtitleInfo.formattingOption.font,
            color: viewModel.subtitleInfo.formattingOption.textColor
        )
        .truncationMode(.middle)
        .if(!viewModel.isUserWalletLocked) {
            $0.skeletonable(isShown: viewModel.isLoadingSubtitle, size: .init(width: 52, height: 12), radius: 3)
        }
    }
}

private extension MainHeaderView {
    struct SubtitleSeparator: View {
        var body: some View {
            Colors.Icon.informative
                .clipShape(Circle())
                .frame(size: .init(bothDimensions: 2.5))
        }
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
