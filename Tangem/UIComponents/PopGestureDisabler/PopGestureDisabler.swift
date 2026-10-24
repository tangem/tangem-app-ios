//
//  PopGestureDisabler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct PopGestureDisabler: UIViewControllerRepresentable {
    var isDisabled = true

    func makeUIViewController(context: Context) -> PopGestureDisablingController {
        PopGestureDisablingController()
    }

    func updateUIViewController(_ controller: PopGestureDisablingController, context: Context) {
        controller.isDisabled = isDisabled
    }
}

final class PopGestureDisablingController: UIViewController {
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
