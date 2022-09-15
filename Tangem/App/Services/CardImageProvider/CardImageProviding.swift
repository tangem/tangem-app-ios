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
    func loadImage() -> AnyPublisher<UIImage, Never>
}
