//
//  BottomSheetBaseController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetBaseController: UIViewController {
    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitionDelegate(
        preferredSheetTopInset: preferredSheetTopInset,
        preferredSheetCornerRadius: preferredSheetCornerRadius,
        preferredSheetSizingFactor: preferredSheetSizing.rawValue,
        preferredSheetBackdropColor: preferredSheetBackdropColor
    )

    override var additionalSafeAreaInsets: UIEdgeInsets {
        get {
            .init(
                top: super.additionalSafeAreaInsets.top,
                left: super.additionalSafeAreaInsets.left,
                bottom: super.additionalSafeAreaInsets.bottom,
                right: super.additionalSafeAreaInsets.right
            )
        }
        set {
            super.additionalSafeAreaInsets = newValue
        }
    }

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

    var preferredSheetTopInset: CGFloat = 0 {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetTopInset = preferredSheetTopInset
        }
    }

    var preferredSheetCornerRadius: CGFloat = 8 {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetCornerRadius = preferredSheetCornerRadius
        }
    }

    var preferredSheetSizing: PreferredSheetSizing = .medium {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetSizingFactor = preferredSheetSizing.rawValue
        }
    }

    var preferredSheetBackdropColor: UIColor = .label {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetBackdropColor = preferredSheetBackdropColor
        }
    }

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
}

extension BottomSheetBaseController {
    enum PreferredSheetSizing: CGFloat {
        case adaptive = 0
        case small = 0.25
        case medium = 0.5
        case large = 0.75
    }
}
