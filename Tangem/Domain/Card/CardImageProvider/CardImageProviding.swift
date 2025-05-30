//
//  CardImageProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

protocol CardImageProviding {
    func loadLargeImage() async -> ImageValue
    func loadSmallImage() async -> ImageValue

    func loadLargeUIImage() async -> UIImage
    func loadSmallUIImage() async -> UIImage
}

struct ImageValue {
    let image: Image
}

extension CardImageProviding {
    func loadLargeImage() async -> ImageValue {
        let uiImage = await loadLargeUIImage()
        let image = Image(uiImage: uiImage)
        return ImageValue(image: image)
    }

    func loadSmallImage() async -> ImageValue {
        let uiImage = await loadSmallUIImage()
        let image = Image(uiImage: uiImage)
        return ImageValue(image: image)
    }
}
