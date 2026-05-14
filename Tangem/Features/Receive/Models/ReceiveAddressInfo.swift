//
//  ReceiveAddressInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import BlockchainSdk
import TangemFoundation

struct ReceiveAddressInfo: Identifiable, Hashable {
    var id: String { address }
    let address: String
    let type: AddressType
    let localizedName: String

    /// - Note: Generated lazily on first access and cached for subsequent reads to prevent recreating `UIImage` again and again in UI.
    var addressQRImage: UIImage { qrImageCache.image }

    @IgnoredEquatable
    private var qrImageCache: QRImageCache

    init(
        address: String,
        type: AddressType,
        localizedName: String,
        qrBackgroundColor: UIColor,
        qrForegroundColor: UIColor
    ) {
        self.address = address
        self.type = type
        self.localizedName = localizedName
        qrImageCache = QRImageCache(
            address: address,
            backgroundColor: qrBackgroundColor,
            foregroundColor: qrForegroundColor
        )
    }
}

// MARK: - Auxiliary types

private extension ReceiveAddressInfo {
    /// A reference-typed lazy holder for the generated QR `UIImage`, the cached image is shared across all struct copies.
    final class QRImageCache {
        private let address: String
        private let backgroundColor: UIColor
        private let foregroundColor: UIColor
        private var cachedImage: UIImage?

        init(address: String, backgroundColor: UIColor, foregroundColor: UIColor) {
            self.address = address
            self.backgroundColor = backgroundColor
            self.foregroundColor = foregroundColor
        }

        var image: UIImage {
            ensureOnMainQueue()

            if let cachedImage {
                return cachedImage
            }

            let image = QrCodeGenerator.generateQRCode(
                from: address,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
            cachedImage = image

            return image
        }
    }
}
