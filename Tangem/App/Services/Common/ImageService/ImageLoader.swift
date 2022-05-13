//
//  ImageLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemSdk

struct DownloadedImage: Equatable {
    let path: URL
    let image: UIImage?
}

class ImageLoader {
    enum ImageLoaderError: String, Error, LocalizedError {
        case failed = "Failed to parse image from response"
        
        var errorDescription: String? {
            self.rawValue
        }
    }
    
    static let service: ImageLoader = {
        ImageLoader()
    }()

    private let session: URLSession
    private let cache: ImageCacheType = ImageCache()

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func downloadImage(at url: URL) -> AnyPublisher<DownloadedImage, Never> {
        if let image = cache[url] {
            return Just(DownloadedImage(path: url, image: image))
                .eraseToAnyPublisher()
        }

        return session
            .dataTaskPublisher(for: url)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .tryMap { data, response -> DownloadedImage in
                if let image = UIImage(data: data) {
                    return DownloadedImage(path: url, image: image)
                }

                throw ImageLoaderError.failed
            }
            .handleEvents(receiveOutput: { (image) in
                guard let image = image.image else { return }

                self.cache[url] = image
            })
            .replaceError(with: DownloadedImage(path: url, image: nil))
            .eraseToAnyPublisher()
    }

}
