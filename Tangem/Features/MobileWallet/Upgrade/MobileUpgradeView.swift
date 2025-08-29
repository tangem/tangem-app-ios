//
//  MobileUpgradeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileUpgradeView: View {
    typealias ViewModel = MobileUpgradeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 6, trailing: 16))
            .alert(item: $viewModel.alert, content: { $0.alert })
            .actionSheet(item: $viewModel.actionSheet, content: { $0.sheet })
    }
}

// MARK: - Subviews

private extension MobileUpgradeView {
    var content: some View {
        VStack(spacing: 6) {
            CloseButton(dismiss: viewModel.onCloseTap)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .bottom) {
                info(item: viewModel.info)
                actionButtons
            }
        }
    }

    func info(item: ViewModel.InfoItem) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                logo(icon: item.icon)

                Text(item.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)

                traits(items: item.traits)
                    .padding(.top, 32)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 40)
        }
    }

    func logo(icon: ImageType) -> some View {
        icon.image
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 30)
            .foregroundStyle(Colors.Icon.primary1)
            .padding(.vertical, 22)
            .padding(.horizontal, 24)
            .background(
                Colors.Field.focused
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            )
    }

    func traits(items: [ViewModel.TraitItem]) -> some View {
        VStack(spacing: 28) {
            ForEach(items) { item in
                HStack(spacing: 16) {
                    item.icon.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .background(
                            Colors.Control.unchecked
                                .clipShape(Circle())
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                        Text(item.subtitle)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    var actionButtons: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.buyButtonTitle,
                style: .secondary,
                action: viewModel.onBuyTap
            )

            MainButton(
                title: viewModel.scanButtonTitle,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                action: viewModel.onScanTap
            )
        }
    }
}
