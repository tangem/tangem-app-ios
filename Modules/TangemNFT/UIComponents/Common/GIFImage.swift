//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct GIFImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: Placeholder

    var body: some View {
        KFAnimatedImage(url)
            .cancelOnDisappear(true)
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
    }
}

#if DEBUG
#Preview {
    GIFImage(
        url: URL(string: "https://i.seadn.io/gcs/files/e31424bc14dd91a653cb01857cac52a4.gif?w=500&auto=format"),
        placeholder: Color.red
    )
}
#endif
