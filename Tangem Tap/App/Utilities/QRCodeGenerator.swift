//
//  QRCodeGenerator.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit

enum QrCodeGenerator {
    static func generateQRCode(from string: String) -> UIImage {
        let data = string.data(using: String.Encoding.ascii)

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let transform = CGAffineTransform(scaleX: 7, y: 7)
        
        filter.setValue(data, forKey: "inputMessage")
        if let ciQRImage = filter.outputImage?.transformed(by: transform),
           let cgImage = context.createCGImage(ciQRImage, from: ciQRImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "xmark") ?? UIImage()
    }
}
