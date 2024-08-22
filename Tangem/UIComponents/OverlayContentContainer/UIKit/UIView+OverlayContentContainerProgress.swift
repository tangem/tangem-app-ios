//
//  UIView+OverlayContentContainerProgress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    class func animate(
        with animationContext: OverlayContentContainerProgress.AnimationContext,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void,
        completion: ((_ flag: Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: animationContext.duration,
            delay: .zero,
            options: options.union(animationContext.curve.toAnimationOptions()),
            animations: animations,
            completion: completion
        )
    }
}
