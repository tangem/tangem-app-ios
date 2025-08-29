//
//  QRCodeGenerator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import CoreImage.CIFilterBuiltins

enum QrCodeGenerator {
    static func generateQRCode(
        from string: String,
        backgroundColor: UIColor = .white,
        foregroundColor: UIColor = .black
    ) -> UIImage {
        let data = string.data(using: .utf8)

        let context = CIContext()
        let transform = CGAffineTransform(scaleX: 7, y: 7)

        let filter = CIFilter.qrCodeGenerator()

        filter.setValue(data, forKey: "inputMessage")

        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = filter.outputImage
        colorFilter.color0 = CIColor(color: foregroundColor)
        colorFilter.color1 = CIColor(color: backgroundColor)

        guard let ciQRImage = colorFilter.outputImage?.transformed(by: transform),
              let cgImage = context.createCGImage(ciQRImage, from: ciQRImage.extent)
        else {
            return UIImage()
        }

        let qrImage = UIImage(cgImage: cgImage)

        return qrImage
    }
}
