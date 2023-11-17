//
//  TokenIconItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenIconItemView: View {
    let viewModel: TokenIconItemViewModel

    private let imageSize = CGSize(width: 36, height: 36)
    private let networkIconSize = CGSize(width: 16, height: 16)

    init(viewModel: TokenIconItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            IconView(url: viewModel.imageURL, size: imageSize)

            if let networkIcon = viewModel.networkURL {
                IconView(url: networkIcon, size: networkIconSize)
                    .frame(size: networkIconSize)
                    .padding(.all, 1)
                    .background(Colors.Background.primary)
                    .cornerRadius(networkIconSize.height / 2)
                    .offset(x: 6, y: -6)
            }
        }
    }
}

#Preview("TokenIconItemView") {
    TokenIconItemView(
        viewModel: TokenIconItemViewModel(
            imageURL: TokenIconURLBuilder().iconURL(id: "tether", size: .large),
            networkURL: TokenIconURLBuilder().iconURL(id: "ethereum", size: .small)
        )
    )
    .background(Colors.Background.secondary.ignoresSafeArea(.all))
}
