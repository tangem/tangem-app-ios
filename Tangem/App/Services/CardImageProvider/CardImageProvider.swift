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

protocol CardImageProviding {
    func loadImage() -> AnyPublisher<UIImage, Never>
}

class CardImageProvider {
    @Injected(\.cardImageLoader) private var imageLoader: CardImageLoaderProtocol
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    private let isSupportOnlineImage: Bool
    private let cardId: String
    private let cardPublicKey: Data
    private let cardArtwork: CardArtwork

    init(isSupportOnlineImage: Bool, cardId: String, cardPublicKey: Data, cardArtwork: CardArtwork) {
        self.isSupportOnlineImage = isSupportOnlineImage
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.cardArtwork = cardArtwork
    }
}

extension CardImageProvider: CardImageProviding {
    func loadImage() -> AnyPublisher<UIImage, Never> {
        loadImage(cardArtwork: cardArtwork)
    }

    private func loadImage(cardArtwork: CardArtwork) -> AnyPublisher<UIImage, Never> {
        switch cardArtwork {
        case let .artwork(artworkInfo):
            return self.loadImage(artworkInfo: artworkInfo)
        case .noArtwork:
            return self.loadImage(artworkInfo: nil)
        case .notLoaded:
            return loadArtworkInfo()
                .flatMap { [weak self] cardArtwork -> AnyPublisher<UIImage, Never> in
                    guard let self = self else {
                        return Just(UIImage(named: "dark_card")!).eraseToAnyPublisher()
                    }

                    return self.loadImage(cardArtwork: cardArtwork)
                }
                .eraseToAnyPublisher()
        }
    }

    private func loadImage(artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Never> {
        imageLoader.loadImage(cid: cardId, cardPublicKey: cardPublicKey, artworkInfo: artworkInfo)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

private extension CardImageProvider {
    func loadArtworkInfo() -> AnyPublisher<CardArtwork, Never> {
        guard isSupportOnlineImage else {
            return Just(.noArtwork).eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.success(.noArtwork))
                return
            }

            self.tangemSdkProvider.sdk.loadCardInfo(cardPublicKey: self.cardPublicKey, cardId: self.cardId) { result in
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
}
