//
//  WebImage.swift
//  Tangem Tap
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
    var imageDownloaded: Bool {
        downloadedImage?.image != nil
    }
    
    @ViewBuilder
    var image: some View {
        ZStack {
            placeholder
                .opacity(img.size == .zero ? 1.0 : 0.0)
                .animation(.easeInOut)
            Image(uiImage: img)
                .resizable()
                .opacity(img.size == .zero ? 0.0 : 1.0)
                .animation(.easeInOut)
        }
    }
    
    var body: some View {
        if imagePath == downloadedImage?.path {
            image
        } else {
            image
                .onReceive(ImageLoader.service.downloadImage(at: imagePath), perform: { loadedImage in
                    guard downloadedImage != loadedImage else { return }
                    
                    withAnimation {
                        downloadedImage = loadedImage
                    }
                })
        }
    }
    
}
