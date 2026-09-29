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
    var isDisabled = true

    func makeUIViewController(context: Context) -> PolymarketPopGestureController {
        PolymarketPopGestureController()
    }

    func updateUIViewController(_ controller: PolymarketPopGestureController, context: Context) {
        controller.isDisabled = isDisabled
    }
}

final class PolymarketPopGestureController: UIViewController {
    var isDisabled = true {
        didSet { setPopGesture(enabled: !isDisabled) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setPopGesture(enabled: !isDisabled)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        setPopGesture(enabled: true)
    }

    private func setPopGesture(enabled: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
    }
}
