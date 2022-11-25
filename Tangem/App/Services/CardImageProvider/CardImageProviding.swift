//
//  CardImageProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import Combine

protocol CardImageProviding {
    func loadImage(cardId: String, cardPublicKey: Data) -> AnyPublisher<UIImage, Never>
    func loadImage(cardId: String, cardPublicKey: Data, artwork: CardArtwork?) -> AnyPublisher<UIImage, Never>
    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Never>
}
