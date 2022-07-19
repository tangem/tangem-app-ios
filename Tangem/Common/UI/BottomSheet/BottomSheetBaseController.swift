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

    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitionDelegate(
        preferredSheetCornerRadius: preferredSheetCornerRadius,
        preferredSheetSizingFactor: preferredSheetSizing.rawValue,
        preferredSheetBackdropColor: preferredSheetBackdropColor
    )
}

extension BottomSheetBaseController {
    enum PreferredSheetSizing: CGFloat {
        case adaptive = 0
        case small = 0.25
        case medium = 0.5
        case large = 0.75
    }
}
