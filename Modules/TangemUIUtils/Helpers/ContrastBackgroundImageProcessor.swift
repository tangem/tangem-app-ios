//
//  KingfisherImageProcessors.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

public struct ContrastBackgroundImageProcessor: ImageProcessor {
    public var identifier: String {
        "com.tangem.ContrastBackgroundImageProcessor"
    }

    let backgroundColor: UIColor

    public init(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
    }

    /// An image that is 100% black on a clear background would have the average color of 0.
    /// A low-contrast image on a clear background would have the average color of 0.03-0.06 even if it's not black but
    /// a shade of blue, for example. 7% was chosen to update as many low-contrast images as possible
    /// without breaking those that already look good
    private let averageColorPercentageThreshold = 0.07

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        guard case .image(let originalImage) = item else {
            fatalError("Not supported")
        }

        if let averageColorPercentage = originalImage.averageColorPercentage,
           averageColorPercentage >= averageColorPercentageThreshold {
            return originalImage
        }

        let canvasSide = max(originalImage.size.width, originalImage.size.height)
        let canvasSize = CGSize(width: canvasSide, height: canvasSide)
        let canvasRect = CGRect(origin: .zero, size: canvasSize)
        UIGraphicsBeginImageContextWithOptions(canvasRect.size, false, 0.0)

        backgroundColor.setFill()
        UIRectFill(canvasRect)

        let centeredImageRect = CGRect(
            x: (canvasSize.width - originalImage.size.width) / 2,
            y: (canvasSize.height - originalImage.size.height) / 2,
            width: originalImage.size.width,
            height: originalImage.size.height
        )

        originalImage.draw(in: centeredImageRect)

        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let renderedImage else {
            assertionFailure("Failed to render the image")
            return originalImage
        }

        return renderedImage
    }
}
