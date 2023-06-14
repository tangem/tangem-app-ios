//
//  View+snapshot.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @MainActor
    func snapshot(displayScale: CGFloat) -> UIImage? {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: self)
            renderer.scale = displayScale
            return renderer.uiImage
        } else {
            let yOffsetFix = -24.0
            let controller = UIHostingController(rootView: offset(y: yOffsetFix))

            guard let view = controller.view else { return nil }

            let targetSize = view.intrinsicContentSize
            let rect = CGRect(origin: .zero, size: targetSize)
            view.frame = rect

            let format = UIGraphicsImageRendererFormat.preferred()
            format.scale = displayScale

            return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
                _ = view.drawHierarchy(in: rect, afterScreenUpdates: true)
            }
        }
    }
}
