//
//  WebImage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct WebImage: View {
    @State var downloadedImage: DownloadedImage? = nil
    let imagePath: URL
    var placeholder: AnyView? = nil

    var img: UIImage {
        downloadedImage?.image ?? UIImage()
    }

    var isLoadingImage: Bool {
        downloadedImage?.image == nil
    }
    
    var body: some View {
        Image(uiImage: img)
            .resizable()
            .opacity(isLoadingImage ? 0.0 : 1.0)
            .background(
                placeholder
                    .opacity(isLoadingImage ? 1.0 : 0.0)
            )
            .onReceive(ImageLoader.service.downloadImage(at: imagePath), perform: { loadedImage in
                guard downloadedImage != loadedImage else { return }

                withAnimation {
                    downloadedImage = loadedImage
                }
            })
    }

}
