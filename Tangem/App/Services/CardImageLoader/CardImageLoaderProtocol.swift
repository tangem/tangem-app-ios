//
//  CardImageLoaderProtocol.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

protocol CardImageLoaderProtocol {
    func loadImage(cid: String, cardPublicKey: Data, artworkInfo: ArtworkInfo?) -> AnyPublisher<UIImage, Never>
    func loadImage(byNdefLink link: String) -> AnyPublisher<UIImage, Never>
    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Never>
}

private struct CardImageLoaderKey: InjectionKey {
    static var currentValue: CardImageLoaderProtocol = CardImageLoader()
}

extension InjectedValues {
    var cardImageLoader: CardImageLoaderProtocol {
        get { Self[CardImageLoaderKey.self] }
        set { Self[CardImageLoaderKey.self] = newValue }
    }
}
