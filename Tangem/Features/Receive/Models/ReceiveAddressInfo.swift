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

    /// Generated lazily on first access and cached for subsequent reads to prevent recreating `UIImage` again and again in UI.
    var addressQRImage: UIImage { qrImageCache.image }

    /// `@IgnoredEquatable` excludes the cache box from synthesized `Hashable`/`Equatable` — identity is fully
    /// defined by `address`, `type`, and `localizedName`.
    ///
    /// The `ColorScheme` (and therefore the background/foreground `UIColor`s) is decided once at the construction
    /// site and is static — `UIColor.white` / `UIColor.black` / `UIColor.clear`, not trait-aware. An already-generated
    /// `UIImage` therefore never needs to be invalidated for the lifetime of this value, even across Dark Mode /
    /// trait changes. Struct copies share the same cache box, so the QR is generated at most once per logical instance.
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
    /// A reference-typed lazy holder for the generated QR `UIImage`. Allows the enclosing value-type struct
    /// to defer image generation until first access without forcing the whole struct to become a class,
    /// while still sharing the cached image across struct copies.
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
            // Asserts (in internal/debug builds only) that the unsynchronized read/write of `cachedImage`
            // is performed on the main queue, where SwiftUI accesses it. Catches potential races during
            // development without paying any cost in release builds.
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
