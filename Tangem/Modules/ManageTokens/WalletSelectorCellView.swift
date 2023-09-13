//
//  WalletSelectorCellView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletSelectorCellView: View {
    var image: UIImage?
    let name: String
    let isSelected: Bool

    private let imageHeight = 30.0
    private let maxImageWidth = 50.0

    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxImageWidth, minHeight: imageHeight, maxHeight: imageHeight)
            } else {
                SkeletonView()
                    .cornerRadius(3)
                    .frame(width: maxImageWidth, height: imageHeight)
            }

            Text(name)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
        }
    }
}

struct WalletSelectorCellView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WalletSelectorCellView(image: nil, name: "My Wallet", isSelected: true)
        }
    }
}
