//
//  View+ModalDetection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Calls `handler` once on first appear: passes `true` if presented modally, `false` otherwise.
    func onModalDetection(perform handler: @escaping (Bool) -> Void) -> some View {
        background {
            ModalDetectionView(onDetect: handler)
        }
    }
}

private struct ModalDetectionView: UIViewControllerRepresentable {
    let onDetect: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ModalDetectionViewController(onDetect: onDetect)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class ModalDetectionViewController: UIViewController {
    private var didDetect = false

    private let onDetect: (Bool) -> Void

    init(onDetect: @escaping (Bool) -> Void) {
        self.onDetect = onDetect
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !didDetect else { return }
        didDetect = true
        let isModal = presentingViewController != nil
        onDetect(isModal)
    }
}
