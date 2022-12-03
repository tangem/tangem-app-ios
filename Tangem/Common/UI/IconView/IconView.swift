//
//  IconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct IconView: View {
    private let url: URL?
    private let name: String
    private let size: CGSize

    init(url: URL?, name: String, size: CGSize = CGSize(width: 46, height: 46)) {
        self.url = url
        self.name = name
        self.size = size
    }

    var body: some View {
        KFImage(url)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .placeholder { CircleImageTextView(name: name, color: .tangemGrayLight4) }
            .fade(duration: 0.3)
            .forceTransition()
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
            .frame(size: size)
    }
}
