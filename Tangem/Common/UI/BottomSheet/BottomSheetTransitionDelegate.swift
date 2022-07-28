//
//  BottomSheetTransitionDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var preferredSheetCornerRadius: CGFloat
    var preferredSheetBackgroundColor: UIColor
    var backgroundAlpha: CGFloat = 0.3

    var tapOutsideToDismissEnabled: Bool = true {
        didSet {
            bottomSheetPresentationController?.tapGestureRecognizer.isEnabled = tapOutsideToDismissEnabled
        }
    }

    var swipeDownToDismissEnabled: Bool = true {
        didSet {
            bottomSheetPresentationController?.panToDismissEnabled = swipeDownToDismissEnabled
        }
    }

    private weak var bottomSheetPresentationController: BottomSheetPresentationController?

    init(
        preferredSheetCornerRadius: CGFloat,
        preferredSheetBackgroundColor: UIColor
    ) {
        self.preferredSheetCornerRadius = preferredSheetCornerRadius
        self.preferredSheetBackgroundColor = preferredSheetBackgroundColor

        super.init()
    }

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let bottomSheetPresentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting ?? source,
            sheetCornerRadius: preferredSheetCornerRadius,
            sheetBackgroundColor: preferredSheetBackgroundColor,
            backgroundAlpha: backgroundAlpha
        )

        bottomSheetPresentationController.tapGestureRecognizer.isEnabled = tapOutsideToDismissEnabled
        bottomSheetPresentationController.panToDismissEnabled = swipeDownToDismissEnabled

        self.bottomSheetPresentationController = bottomSheetPresentationController

        return bottomSheetPresentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let bottomSheetPresentationController = dismissed.presentationController as? BottomSheetPresentationController,
              bottomSheetPresentationController.bottomSheetInteractiveDismissalTransition.wantsInteractiveStart else {
            return nil
        }

        return bottomSheetPresentationController.bottomSheetInteractiveDismissalTransition
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        animator as? BottomSheetDismissalTransition
    }
}
