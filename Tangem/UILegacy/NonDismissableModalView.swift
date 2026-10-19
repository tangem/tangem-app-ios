//
//  NonDismissableModalView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

protocol NonDismissableHostingControllerDelegate: UIAdaptivePresentationControllerDelegate {
    func didDisappear()
}

final class NonDismissableHostingController: UIViewController {
    weak var delegate: NonDismissableHostingControllerDelegate?

    var isModal: Bool = false {
        didSet { applyToPresentedController() }
    }

    private var presentedController: UIViewController? {
        var controller: UIViewController? = parent
        while let parent = controller?.parent {
            controller = parent
        }
        return controller
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyToPresentedController()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard presentedController?.isBeingDismissed ?? true || presentedController?.presentingViewController == nil else {
            return
        }

        delegate?.didDisappear()
    }

    private func applyToPresentedController() {
        guard let presentedController else { return }

        presentedController.isModalInPresentation = isModal
        presentedController.presentationController?.delegate = delegate
    }
}

struct NonDismissableModalView: UIViewControllerRepresentable {
    let modal: Bool
    let onDismissalAttempt: (() -> Void)?
    let onDismissed: (() -> Void)?

    func makeUIViewController(context: Context) -> NonDismissableHostingController {
        let controller = NonDismissableHostingController()
        controller.delegate = context.coordinator
        controller.isModal = modal
        return controller
    }

    func updateUIViewController(_ uiViewController: NonDismissableHostingController, context: Context) {
        context.coordinator.modalView = self
        uiViewController.isModal = modal
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NonDismissableHostingControllerDelegate {
        var modalView: NonDismissableModalView

        init(_ modalView: NonDismissableModalView) {
            self.modalView = modalView
        }

        func didDisappear() {
            modalView.onDismissed?()
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !modalView.modal
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            modalView.onDismissalAttempt?()
        }
    }
}

extension View {
    func presentation(modal: Bool = true, onDismissalAttempt: (() -> Void)? = nil, onDismissed: (() -> Void)? = nil) -> some View {
        background(NonDismissableModalView(modal: modal, onDismissalAttempt: onDismissalAttempt, onDismissed: onDismissed))
    }
}
