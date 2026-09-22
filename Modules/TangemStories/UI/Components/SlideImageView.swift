//
//  SlideImageView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

/// Overlay-over-base pattern: keeps `scaledToFill` from inflating the layout beyond the container.
struct SlideImageView: View {
    let url: URL?
    var contentMode: StoryContentMode = .cover

    var body: some View {
        Color.black
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if let url {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: contentMode == .cover ? .fill : .fit)
                }
            }
            .clipped()
    }
}
