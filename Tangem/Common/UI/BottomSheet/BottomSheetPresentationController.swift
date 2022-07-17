//
//  BottomSheetPresentationController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetPresentationController: UIPresentationController {
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = sheetBackgroundColor
        view.alpha = 0
        return view
    }()

    let bottomSheetInteractiveDismissalTransition = BottomSheetDismissalTransition()

    let sheetTopInset: CGFloat
    let sheetCornerRadius: CGFloat
    let sheetSizingFactor: CGFloat
    let sheetBackgroundColor: UIColor

    private(set) lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan))
    var panToDismissEnabled: Bool = true

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        sheetTopInset: CGFloat,
        sheetCornerRadius: CGFloat,
        sheetSizingFactor: CGFloat,
        sheetBackgroundColor: UIColor
    ) {
        self.sheetTopInset = sheetTopInset
        self.sheetCornerRadius = sheetCornerRadius
        self.sheetSizingFactor = sheetSizingFactor
        self.sheetBackgroundColor = sheetBackgroundColor
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    @objc private func onTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard
            let presentedView = presentedView,
            let containerView = containerView,
            !presentedView.frame.contains(gestureRecognizer.location(in: containerView))
        else {
            return
        }

        presentingViewController.dismiss(animated: true)
    }

    @objc private func onPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let presentedView = presentedView else {
            return
        }

        let translation = gestureRecognizer.translation(in: presentedView)

        let progress = translation.y / presentedView.frame.height

        switch gestureRecognizer.state {
        case .began:
            bottomSheetInteractiveDismissalTransition.start(
                moving: presentedView, interactiveDismissal: panToDismissEnabled
            )
        case .changed:
            if panToDismissEnabled && progress > 0 && !presentedViewController.isBeingDismissed {
                presentingViewController.dismiss(animated: true)
            }
            bottomSheetInteractiveDismissalTransition.move(
                presentedView, using: translation.y
            )
        default:
            let velocity = gestureRecognizer.velocity(in: presentedView)
            bottomSheetInteractiveDismissalTransition.stop(
                moving: presentedView, at: translation.y, with: velocity
            )
        }
    }

    override func presentationTransitionWillBegin() {
        guard let presentedView = presentedView else {
            return
        }

        presentedView.addGestureRecognizer(panGestureRecognizer)

        presentedView.layer.cornerRadius = sheetCornerRadius
        presentedView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
        ]

        guard let containerView = containerView else {
            return
        }

        containerView.addGestureRecognizer(tapGestureRecognizer)

        containerView.addSubview(backgroundView)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(
                equalTo: containerView.topAnchor
            ),
            backgroundView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor
            ),
            backgroundView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor
            ),
            backgroundView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor
            ),
        ])

        containerView.addSubview(presentedView)

        presentedView.translatesAutoresizingMaskIntoConstraints = false

        let preferredHeightConstraint = presentedView.heightAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.heightAnchor,
            multiplier: sheetSizingFactor
        )

        preferredHeightConstraint.priority = .fittingSizeLevel

        let maxHeightConstraint = presentedView.topAnchor.constraint(
            greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor,
            constant: 0
        )

        // Prevents conflicts with the height constraint used by the animated transition
        maxHeightConstraint.priority = .required - 1

        let heightConstraint = presentedView.heightAnchor.constraint(
            equalToConstant: 0
        )

        let bottomConstraint = presentedView.bottomAnchor.constraint(
            equalTo: containerView.bottomAnchor
        )

        NSLayoutConstraint.activate([
            maxHeightConstraint,
            presentedView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor
            ),
            presentedView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor
            ),
            bottomConstraint,
            preferredHeightConstraint,
        ])

        bottomSheetInteractiveDismissalTransition.bottomConstraint = bottomConstraint
        bottomSheetInteractiveDismissalTransition.heightConstraint = heightConstraint

        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }

        transitionCoordinator.animate { context in
            self.backgroundView.alpha = 0.3
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            backgroundView.removeFromSuperview()
            presentedView?.removeGestureRecognizer(panGestureRecognizer)
            containerView?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    override func dismissalTransitionWillBegin() {
        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }

        transitionCoordinator.animate { context in
            self.backgroundView.alpha = 0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            backgroundView.removeFromSuperview()
            presentedView?.removeGestureRecognizer(panGestureRecognizer)
            containerView?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        panGestureRecognizer.isEnabled = false // This will cancel any ongoing pan gesture
        coordinator.animate(alongsideTransition: nil) { context in
            self.panGestureRecognizer.isEnabled = true
        }
    }

}
