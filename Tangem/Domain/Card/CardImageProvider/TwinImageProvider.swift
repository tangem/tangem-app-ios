//
//  TwinImageProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import TangemAssets
import TangemNetworkUtils

struct TwinImageProvider {
    private let imageCache = CardImageProviderCache()
    private let defaultImage = Assets.Onboarding.darkCard.uiImage

    func loadTwinImage(cardNumber: Int) async -> UIImage {
        let image = try? await loadTwinImagePublisher(cardNumber: cardNumber).async()
        return image ?? defaultImage
    }

    func loadTwinImagePublisher(cardNumber: Int) -> AnyPublisher<UIImage, Never> {
        let cacheKey = "twin_\(cardNumber)"
        if let image = imageCache.getImageFromCache(for: cacheKey) {
            return .just(output: image)
        }

        let imageName = cardNumber == 1 ? "card_tg085" : "card_tg086"
        return loadImage(name: imageName)
            .handleEvents(receiveOutput: { image in
                if let image {
                    imageCache.cacheImage(image, for: cacheKey)
                }
            })
            .replaceNil(with: defaultImage)
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }

    private func loadImage(name: String) -> AnyPublisher<UIImage?, URLError> {
        let session = TangemURLSessionBuilder.makeSession(configuration: .imageFetchingConfiguration)

        return session
            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
            .subscribe(on: DispatchQueue.global())
            .map { UIImage(data: $0.0) }
            .eraseToAnyPublisher()
    }
}
