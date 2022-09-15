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

    private let isSupportOnlineImage: Bool
    private let cardId: String
    private let cardPublicKey: Data
    private let defaultImage = UIImage(named: "dark_card")!

    init(isSupportOnlineImage: Bool = true, cardId: String, cardPublicKey: Data) {
        self.isSupportOnlineImage = isSupportOnlineImage
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
    }
}

extension CardImageProvider: CardImageProviding {
    func loadImage() -> AnyPublisher<UIImage, Never> {
        loadImage(cardArtwork: CardImageProvider.cardArtworkCache[cardId] ?? .notLoaded)
            .replaceError(with: defaultImage)
            .eraseToAnyPublisher()
    }

    private func loadImage(cardArtwork: CardArtwork) -> AnyPublisher<UIImage, Error> {
        switch cardArtwork {
        case let .artwork(artworkInfo):
            return loadImage(artworkInfo: artworkInfo)
        case .noArtwork:
            return loadImage(artworkInfo: nil)
        case .notLoaded:
            return loadArtworkInfo()
                .tryMap { cardArtwork -> AnyPublisher<UIImage, Error> in
                    CardImageProvider.cardArtworkCache[cardId] = cardArtwork
                    return loadImage(cardArtwork: cardArtwork)
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        }
    }

    private func loadImage(artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Error> {
        if let number = getTwinNumberFor(for: cardId) {
            return loadTwinImage(number: number)
        }

        if let artworkInfo = artworkInfo {
            return loadImage(artworkInfo: artworkInfo)
        }

        return .justWithError(output: defaultImage)
    }
}

private extension CardImageProvider {
    func loadArtworkInfo() -> AnyPublisher<CardArtwork, Never> {
        guard isSupportOnlineImage else {
            return Just(.noArtwork).eraseToAnyPublisher()
        }

        return Future { promise in
            tangemSdkProvider.sdk.loadCardInfo(cardPublicKey: self.cardPublicKey, cardId: self.cardId) { result in
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

    func loadImage(artworkInfo: ArtworkInfo) -> AnyPublisher<UIImage, Error> {
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
        let cacheKey = cardId + "_\(number)"

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
