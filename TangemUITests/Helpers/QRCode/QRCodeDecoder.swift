//
//  QRCodeDecoder.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import CoreImage
import XCTest

/// Decodes the text encoded in a QR code captured from a UI element's screenshot.
enum QRCodeDecoder {
    /// Detector (and its CIContext) are expensive to build; reuse one across all decodes.
    private static let detector = CIDetector(
        ofType: CIDetectorTypeQRCode,
        context: CIContext(),
        options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    )

    static func decode(from element: XCUIElement) -> String? {
        decode(image: element.screenshot().image)
    }

    static func decode(image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let features = detector?.features(in: ciImage) ?? []
        return features
            .compactMap { ($0 as? CIQRCodeFeature)?.messageString }
            .first
    }

    /// Removes the zero-width spaces and whitespace the address label uses for chunked rendering.
    static func normalizeAddress(_ address: String) -> String {
        address
            .replacingOccurrences(of: "\u{200B}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
