//
//  OverlayContentContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

/// Interface that exposes `OverlayContentContainerViewController`'s API into SwiftUI.
protocol OverlayContentContainer {
    var cornerRadius: CGFloat { get }
    var isScrollViewLocked: Bool { get }

    func installOverlay(_ overlayView: some View)
    func removeOverlay()
}
