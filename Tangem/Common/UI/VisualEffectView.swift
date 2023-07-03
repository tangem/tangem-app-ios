//
//  VisualEffectView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct VisualEffectView: UIViewRepresentable {
    let effect: UIBlurEffect

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

// MARK: - Convenience extensions

extension VisualEffectView {
    init(style: UIBlurEffect.Style) {
        self.init(effect: .init(style: style))
    }
}
