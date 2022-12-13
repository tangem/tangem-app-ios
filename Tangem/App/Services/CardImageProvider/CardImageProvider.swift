//
//  CardImageProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemSdk

struct CardImageProvider {
    private static var cardArtworkCache: [String: CardArtwork] = [:]
    private static var imageCache = NSCache<NSString, UIImage>()

    @Injected(\.cardImageLoader) private var imageLoader: CardImageLoaderProtocol

    private let supportsOnlineImage: Bool
    private let defaultImage = UIImage(named: "dark_card")!
    private let cacheQueue = DispatchQueue(label: "card_image_cache_queue")

    private let cardVerifier: OnlineCardVerifier

    init(supportsOnlineImage: Bool = true) {
        self.supportsOnlineImage = supportsOnlineImage

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        let networkService = NetworkService(configuration: configuration)
        self.cardVerifier = OnlineCardVerifier(with: networkService)
    }

    func cardArtwork(for cardId: String) -> CardArtwork? {
        Self.cardArtworkCache[cardId]
    }
}

// MARK: - CardImageProviding

extension CardImageProvider: CardImageProviding {
    func loadImage(cardId: String, cardPublicKey: Data) -> AnyPublisher<UIImage, Never> {
        loadImage(cardId: cardId, cardPublicKey: cardPublicKey, artwork: nil)
    }

    func loadImage(cardId: String, cardPublicKey: Data, artwork: CardArtwork?) -> AnyPublisher<UIImage, Never> {
        if SaltPayUtil().isPrimaryCard(batchId: String(cardId.prefix(4))) {
            return Just(UIImage(named: "saltpay")!).eraseToAnyPublisher()
        }

        guard supportsOnlineImage else {
            return Just(defaultImage).eraseToAnyPublisher()
        }

        let cardArtwork = artwork ?? cardArtwork(for: cardId) ?? .notLoaded

        return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: cardArtwork)
            .replaceError(with: defaultImage)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Never> {
        let cacheKey = "twin_\(number)"

        if let image = getImageFromCache(for: cacheKey) {
            return Just(image)
                .eraseToAnyPublisher()
        }

        return imageLoader.loadTwinImage(for: number)
            .handleEvents(receiveOutput: { image in
                cacheImage(image, for: cacheKey)
            })
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CardImageProvider {
    func loadImage(cardId: String, cardPublicKey: Data, cardArtwork: CardArtwork) -> AnyPublisher<UIImage, Error> {
        if let number = getTwinNumberFor(for: cardId) {
            return loadTwinImage(for: number)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        if let cachedImage = getImageFromCache(for: cardId) {
            return .justWithError(output: cachedImage)
        }

        switch cardArtwork {
        case .noArtwork:
            return .justWithError(output: defaultImage)
        case .notLoaded:
            return loadArtworkInfo(cardId: cardId, cardPublicKey: cardPublicKey)
                .tryMap {
                    loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: $0)
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        case let .artwork(artworkInfo):
            return self.imageLoader
                .loadImage(cid: cardId, cardPublicKey: cardPublicKey, artworkInfoId: artworkInfo.id)
                .handleEvents(receiveOutput: { image in
                    cacheImage(image, for: cardId)
                })
                .eraseToAnyPublisher()
        }
    }

    func loadArtworkInfo(cardId: String, cardPublicKey: Data) -> AnyPublisher<CardArtwork, Never> {
        cardVerifier.getCardInfo(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { info in
                if let artwork = info.artwork {
                    let cardArtwork = CardArtwork.artwork(artwork)
                    CardImageProvider.cardArtworkCache[cardId] = cardArtwork
                    return cardArtwork
                } else {
                    return .noArtwork
                }
            }
            .replaceError(with: CardArtwork.noArtwork)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getTwinNumberFor(for cardId: String) -> Int? {
        let prefix = String(cardId.prefix(4)).uppercased()

        return TwinCardSeries.allCases.first(where: {
            prefix.elementsEqual($0.rawValue.uppercased())
        })?.number
    }

    func cacheImage(_ image: UIImage, for key: String) {
        cacheQueue.sync {
            CardImageProvider.imageCache.setObject(image, forKey: NSString(string: key))
        }
    }

    func getImageFromCache(for key: String) -> UIImage? {
        cacheQueue.sync {
            CardImageProvider.imageCache.object(forKey: NSString(string: key))
        }
    }
}
