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
    private static var imageCache: [String: UIImage] = [:]

    @Injected(\.cardImageLoader) private var imageLoader: CardImageLoaderProtocol
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    private let supportsOnlineImage: Bool
    private let defaultImage = UIImage(named: "dark_card")!

    init(supportsOnlineImage: Bool = true) {
        self.supportsOnlineImage = supportsOnlineImage
    }

    func cardArtwork(for cardId: String) -> CardArtwork? {
        Self.cardArtworkCache[cardId]
    }
}

extension CardImageProvider: CardImageProviding {
    func loadImage(cardId: String, cardPublicKey: Data) -> AnyPublisher<UIImage, Never> {
        guard supportsOnlineImage else {
            return Just(defaultImage).eraseToAnyPublisher()
        }

        return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: CardImageProvider.cardArtworkCache[cardId] ?? .notLoaded)
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }

    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Never> {
        guard supportsOnlineImage else {
            return Just(defaultImage).eraseToAnyPublisher()
        }

        return loadTwinImage(number: number)
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }
}

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
        return Future { promise in
            tangemSdkProvider.sdk.loadCardInfo(cardPublicKey: cardPublicKey, cardId: cardId) { result in
                switch result {
                case .success(let info):
                    promise(.success(info.artwork.map { .artwork($0) } ?? .noArtwork))
                case .failure:
                    promise(.success(.noArtwork))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func loadImage(cardId: String, cardPublicKey: Data, artworkInfo: ArtworkInfo) -> AnyPublisher<UIImage, Error> {
        if let image = CardImageProvider.imageCache[cardId] {
            return .justWithError(output: image)
        }

        return imageLoader.loadImage(cid: cardId, cardPublicKey: cardPublicKey, artworkInfoId: artworkInfo.id)
            .handleEvents(receiveOutput: { image in
                CardImageProvider.imageCache[cardId] = image
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func loadTwinImage(number: Int) -> AnyPublisher<UIImage, Error> {
        let cacheKey = "twin_\(number)"

        if let image = CardImageProvider.imageCache[cacheKey] {
            return .justWithError(output: image)
        }

        return imageLoader.loadTwinImage(for: number)
            .handleEvents(receiveOutput: { image in
                CardImageProvider.imageCache[cacheKey] = image
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func getTwinNumberFor(for cardId: String) -> Int? {
        let prefix = String(cardId.prefix(4)).uppercased()

        return TwinCardSeries.allCases.first(where: {
            prefix.elementsEqual($0.rawValue.uppercased())
        })?.number
    }
}
