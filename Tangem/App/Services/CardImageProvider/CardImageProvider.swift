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
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    private let supportsOnlineImage: Bool
    private let defaultImage = UIImage(named: "dark_card")!
    private let cacheQueue = DispatchQueue(label: "card_image_cache_queue")

    private let cardVerifier = OnlineCardVerifier()

    init(supportsOnlineImage: Bool = true) {
        self.supportsOnlineImage = supportsOnlineImage
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

        let cardArtwork = CardImageProvider.cardArtworkCache[cardId] ?? artwork ?? .notLoaded

        return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: cardArtwork)
            .replaceError(with: defaultImage)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Never> {
        guard supportsOnlineImage else {
            return Just(defaultImage).eraseToAnyPublisher()
        }

        return loadTwinImage(number: number)
            .replaceError(with: defaultImage)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CardImageProvider {
    func loadImage(cardId: String, cardPublicKey: Data, cardArtwork: CardArtwork) -> AnyPublisher<UIImage, Error> {
        if let number = getTwinNumberFor(for: cardId) {
            return loadTwinImage(number: number)
        }

        switch cardArtwork {
        case let .artwork(artworkInfo):
            return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, artworkInfo: artworkInfo)
        case .noArtwork:
            return .justWithError(output: defaultImage)
        case .notLoaded:
            return loadArtworkInfo(cardId: cardId, cardPublicKey: cardPublicKey)
                .tryMap { cardArtwork -> AnyPublisher<UIImage, Error> in
                    CardImageProvider.cardArtworkCache[cardId] = cardArtwork
                    return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: cardArtwork)
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        }
    }

    func loadImage(cardId: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Error> {
        if let number = getTwinNumberFor(for: cardId) {
            return loadTwinImage(number: number)
        }

        if let artworkInfo = artworkInfo {
            return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, artworkInfo: artworkInfo)
        }

        return .justWithError(output: defaultImage)
    }

    func loadArtworkInfo(cardId: String, cardPublicKey: Data) -> AnyPublisher<CardArtwork, Never> {
        cardVerifier.getCardInfo(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { info in
                if let artwork = info.artwork {
                    return .artwork(artwork)
                } else {
                    return .noArtwork
                }
            }
            .replaceError(with: CardArtwork.noArtwork)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func loadImage(cardId: String, cardPublicKey: Data, artworkInfo: ArtworkInfo) -> AnyPublisher<UIImage, Error> {
        if let image = getImage(for: cardId) {
            return .justWithError(output: image)
        }

        return imageLoader.loadImage(cid: cardId, cardPublicKey: cardPublicKey, artworkInfoId: artworkInfo.id)
            .handleEvents(receiveOutput: { image in
                cacheImage(image, for: cardId)
            })
            .eraseToAnyPublisher()
    }

    func loadTwinImage(number: Int) -> AnyPublisher<UIImage, Error> {
        let cacheKey = "twin_\(number)"

        if let image = getImage(for: cacheKey) {
            return .justWithError(output: image)
        }

        return imageLoader.loadTwinImage(for: number)
            .handleEvents(receiveOutput: { image in
                cacheImage(image, for: cacheKey)
            })
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

    func getImage(for key: String) -> UIImage? {
        cacheQueue.sync {
            CardImageProvider.imageCache.object(forKey: NSString(string: key))
        }
    }
}
