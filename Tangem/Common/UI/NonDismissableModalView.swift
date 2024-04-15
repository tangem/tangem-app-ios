//
//  NonDismissableModalView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

//
//
// protocol NonDismissableHostingControllerDelegate: UIAdaptivePresentationControllerDelegate {
//    func didDisappear()
// }

class NonDismissableHostingController2<Content: View>: UIHostingController<Content> {
    weak var delegate: NonDismissableHostingControllerDelegate?

    var isModal: Bool = false

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        parent?.isModalInPresentation = isModal
        parent?.presentationController?.delegate = delegate
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDisappear()
    }
}

struct NonDismissableModalView2<T: View>: UIViewControllerRepresentable {
    let view: T
    let modal: Binding<Bool>
    let onDismissalAttempt: (() -> Void)?
    let onDismissed: (() -> Void)?

    func makeUIViewController(context: Context) -> UIHostingController<T> {
        let controller = NonDismissableHostingController2(rootView: view)
        controller.isModal = modal.wrappedValue
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIHostingController<T>, context: Context) {
        context.coordinator.modalView = self
        uiViewController.rootView = view
        uiViewController.isModalInPresentation = modal.wrappedValue
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NonDismissableHostingControllerDelegate {
        var modalView: NonDismissableModalView2

        init(_ modalView: NonDismissableModalView2) {
            self.modalView = modalView
        }

        func didDisappear() {
            modalView.onDismissed?()
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            print("ZZZ presentationControllerShouldDismiss", !modalView.modal.wrappedValue)
            return !modalView.modal.wrappedValue
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            modalView.onDismissalAttempt?()
        }
    }
}

extension View {
    func presentation2(modal: Binding<Bool>, onDismissalAttempt: (() -> Void)? = nil, onDismissed: (() -> Void)? = nil) -> some View {
        NonDismissableModalView2(view: self, modal: modal, onDismissalAttempt: onDismissalAttempt, onDismissed: onDismissed)
            .edgesIgnoringSafeArea(.bottom) // Otherwise background doesn't stretch all the way
    }
}

//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

// - MARK: old

protocol NonDismissableHostingControllerDelegate: UIAdaptivePresentationControllerDelegate {
    func didDisappear()
}

class NonDismissableHostingController<Content: View>: UIHostingController<Content> {
    weak var delegate: NonDismissableHostingControllerDelegate?

    var isModal: Bool = false

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        parent?.isModalInPresentation = isModal
        parent?.presentationController?.delegate = delegate
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDisappear()
    }
}

struct NonDismissableModalView<T: View>: UIViewControllerRepresentable {
    let view: T
    let modal: Bool
    let onDismissalAttempt: (() -> Void)?
    let onDismissed: (() -> Void)?

    func makeUIViewController(context: Context) -> UIHostingController<T> {
        let controller = NonDismissableHostingController(rootView: view)
        controller.isModal = modal
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIHostingController<T>, context: Context) {
        context.coordinator.modalView = self
        uiViewController.rootView = view
        uiViewController.isModalInPresentation = modal
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
        NonDismissableModalView(view: self, modal: modal, onDismissalAttempt: onDismissalAttempt, onDismissed: onDismissed)
            .edgesIgnoringSafeArea(.bottom) // Otherwise background doesn't stretch all the way
    }
}
