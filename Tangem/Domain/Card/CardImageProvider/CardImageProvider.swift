//
//  CardImageProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation
import TangemAssets
import TangemNetworkUtils
import TangemSdk

struct CardImageProvider {
    private let cardId: String

    private let defaultImage = Assets.Onboarding.darkCard.uiImage
    private let imageCache = CardImageProviderCache()
    private let artworksProvider: CardArtworksProvider

    init(card: CardDTO) {
        self.init(input: Input(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            issuerPublicKey: card.issuer.publicKey,
            firmwareVersionType: card.firmwareVersion.type
        ))
    }

    init(input: Input) {
        cardId = input.cardId

        let session = TangemURLSessionBuilder.makeSession(configuration: .imageFetchingConfiguration)
        let networkService = NetworkService(session: session)
        let factory = CardArtworksProviderFactory(networkService: networkService)

        artworksProvider = factory.makeArtworksProvider(
            cardId: input.cardId,
            cardPublicKey: input.cardPublicKey,
            issuerPublicKey: input.issuerPublicKey,
            firmwareVersionType: input.firmwareVersionType
        )
    }
}

// MARK: - CardImageProviding

extension CardImageProvider: CardImageProviding {
    func loadLargeUIImage() async -> UIImage {
        let images = await loadImages()
        return images.large
    }

    func loadSmallUIImage() async -> UIImage {
        let images = await loadImages()
        return images.small
    }
}

// MARK: - Input {

extension CardImageProvider {
    struct Input {
        let cardId: String
        let cardPublicKey: Data
        let issuerPublicKey: Data
        let firmwareVersionType: FirmwareVersion.FirmwareType
    }
}

// MARK: - Private

private extension CardImageProvider {
    func loadImages() async -> Images {
        if let twinNumber = getTwinNumberFor(for: cardId) {
            let twinImage = await TwinImageProvider().loadTwinImage(cardNumber: twinNumber)
            return Images(large: twinImage, small: twinImage)
        }

        if let cached = getCachedImages() {
            return cached
        }

        do {
            let response = try await artworksProvider.loadArtworks()
            let largeImage = parseLargeImage(response: response)
            let smallImage = parseSmallImage(response: response) ?? largeImage
            return Images(large: largeImage, small: smallImage)
        } catch {
            return Images(large: defaultImage, small: defaultImage)
        }
    }

    func getCachedImages() -> Images? {
        let largeImageCacheKey = CacheKeys.large.getKey(cardId: cardId)
        let smallImageCacheKey = CacheKeys.small.getKey(cardId: cardId)

        if let largeCached = imageCache.getImageFromCache(for: largeImageCacheKey) {
            let smallCached = imageCache.getImageFromCache(for: smallImageCacheKey) ?? largeCached
            return Images(large: largeCached, small: smallCached)
        }

        return nil
    }

    func parseSmallImage(response: Artworks) -> UIImage? {
        let cacheKey = CacheKeys.small.getKey(cardId: cardId)

        guard let imageData = response.small?.nilIfEmpty,
              let image = UIImage(data: imageData) else {
            return nil
        }

        imageCache.cacheImage(image, for: cacheKey)

        return image
    }

    func parseLargeImage(response: Artworks) -> UIImage {
        let cacheKey = CacheKeys.large.getKey(cardId: cardId)

        guard let imageData = response.large.nilIfEmpty,
              let image = UIImage(data: imageData) else {
            return defaultImage
        }

        imageCache.cacheImage(image, for: cacheKey)

        return image
    }

    func getTwinNumberFor(for cardId: String) -> Int? {
        let prefix = String(cardId.prefix(4)).uppercased()

        return TwinCardSeries.allCases.first(where: {
            prefix.elementsEqual($0.rawValue.uppercased())
        })?.number
    }
}

// MARK: - Private

private extension CardImageProvider {
    struct Images {
        let large: UIImage
        let small: UIImage
    }

    enum CacheKeys {
        case large
        case small

        func getKey(cardId: String) -> String {
            switch self {
            case .large:
                return "\(cardId)_large"
            case .small:
                return "\(cardId)_small"
            }
        }
    }
}
