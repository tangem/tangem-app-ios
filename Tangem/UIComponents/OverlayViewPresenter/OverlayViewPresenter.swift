//
//  OverlayViewPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

@MainActor
protocol OverlayViewPresenter: AnyObject {
    func present(_ view: OverlayView)
    func dismiss()
}

struct OverlayView: Identifiable {
    let id: String
    let view: AnyView
    let style: PresentationStyle
    let animated: Bool

    init(id: String, view: some View, style: PresentationStyle, animated: Bool = true) {
        self.id = id
        self.view = AnyView(view)
        self.style = style
        self.animated = animated
    }

    enum PresentationStyle: Equatable {
        case sheet
        case fullScreenCover
    }
}

extension OverlayView: Equatable {
    static func == (lhs: OverlayView, rhs: OverlayView) -> Bool {
        lhs.id == rhs.id
            && lhs.style == rhs.style
            && lhs.animated == rhs.animated
    }
}
