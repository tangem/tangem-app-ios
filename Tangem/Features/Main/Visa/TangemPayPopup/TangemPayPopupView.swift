//
//  TangemPayPopupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TangemPayPopupView: View {
    var viewModel: any TangemPayPopupViewModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 24) {
                viewModel.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: .init(bothDimensions: 56))
                    .padding(.top, 64)

                VStack(spacing: 12) {
                    Text(viewModel.title)
                        .style(
                            Fonts.BoldStatic.title3,
                            color: Colors.Text.primary1
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.description)
                        .environment(\.openURL, OpenURLAction(handler: { link in
                            viewModel.onHyperLinkTap(link)
                            return .handled
                        }))
                        .style(
                            Fonts.RegularStatic.subheadline,
                            color: Colors.Text.secondary
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    MainButton(settings: viewModel.primaryButton)

                    if let secondarySettings = viewModel.secondaryButton {
                        MainButton(settings: secondarySettings)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                NavigationBarButton
                    .close(action: viewModel.dismiss)
                    .padding(.top, 8)
            }
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }
}
