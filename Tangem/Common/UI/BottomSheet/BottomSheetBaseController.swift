//
//  BottomSheetBaseController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetBaseController: UIViewController {
    override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            .custom
        }
        set { }
    }

    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            bottomSheetTransitioningDelegate
        }
        set { }
    }

    var cornerRadius: CGFloat = 8 {
        didSet {
            bottomSheetTransitioningDelegate.cornerRadius = cornerRadius
        }
    }

    var backgroundColor: UIColor = (UIColor(named: "Backgroundaction") ?? .label).withAlphaComponent(0.7) {
        didSet {
            bottomSheetTransitioningDelegate.backgroundColor = backgroundColor
        }
    }

    var contentBackgroundColor: UIColor = UIColor.white

    var tapOutsideToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.tapOutsideToDismissEnabled = tapOutsideToDismissEnabled
        }
    }

    var swipeDownToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.swipeDownToDismissEnabled = swipeDownToDismissEnabled
        }
    }

    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitionDelegate(
        cornerRadius: cornerRadius,
        backgroundColor: backgroundColor
    )
}
