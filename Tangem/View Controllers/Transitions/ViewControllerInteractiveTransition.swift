//
//  ViewControllerInteractiveTransition.swift
//  test
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Gennady Berezovsky. All rights reserved.
//

import UIKit

class ViewControllerInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    let viewController: UIViewController
    var panGestureRecognizer: UIPanGestureRecognizer?
    
    public var isActive = false
    var shouldComplete = false
    
    init(viewController: UIViewController, view: UIView?) {
        self.viewController = viewController
        super.init()
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        view?.addGestureRecognizer(recognizer)
        self.panGestureRecognizer = recognizer
        
        self.completionCurve = .linear
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.viewController.view)
        let velocity = recognizer.velocity(in: self.viewController.view)
        
        switch recognizer.state {
        case .began:
            self.isActive = true
            self.viewController.presentingViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            let targetDragAmount = self.viewController.view.bounds.height
            let progress = min(max(translation.y / targetDragAmount, 0.0), 1.0)
            self.update(progress)

            self.shouldComplete = progress > 0.3 || velocity.y > 300
        case .ended, .cancelled:
            if !self.shouldComplete || recognizer.state == .cancelled {
                self.cancel()
            } else {
                self.finish()
            }
            self.isActive = false
        default:
            return
        }
    }
    
    
    
}
