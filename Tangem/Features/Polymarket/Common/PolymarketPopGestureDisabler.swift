//
//  PolymarketPopGestureDisabler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct PolymarketPopGestureDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PolymarketPopGestureController {
        PolymarketPopGestureController()
    }

    func updateUIViewController(_ controller: PolymarketPopGestureController, context: Context) {}
}

final class PolymarketPopGestureController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setPopGesture(enabled: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        setPopGesture(enabled: true)
    }

    private func setPopGesture(enabled: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
    }
}
