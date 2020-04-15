//
//  CustomPresentationController.swift
//  test
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Gennady Berezovsky. All rights reserved.
//

import UIKit

private struct Constants {
    
    static let kAnimationDuration = 0.3
    static let kDragViewHeight: CGFloat = 40
    static let kCornerRadius: CGFloat = 15.0
}

class CustomPresentationController: UIPresentationController {
    
    var presentationWrappingView: UIView!
    
    var dragView: UIView?
    var dimmingView: UIView?
    var dismissInteractor: ViewControllerInteractiveTransition?
    
    fileprivate var propertyAnimator: UIViewPropertyAnimator?
    
    override init(presentedViewController: UIViewController, presenting: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        presentedViewController.modalPresentationStyle = .custom
    }
    
    override var presentedView: UIView? {
        return self.presentationWrappingView
    }
    
    override func presentationTransitionWillBegin() {
        guard let presentedViewControllerView = super.presentedView, let containerView = self.containerView else {
            return
        }
        
        let presentationWrapperView = UIView(frame: self.frameOfPresentedViewInContainerView)
        presentationWrapperView.layer.shadowOpacity = 0.1
        presentationWrapperView.layer.shadowRadius = 5.0
        presentationWrapperView.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        self.presentationWrappingView = presentationWrapperView
        
        let dimmingView = UIImageView(frame: containerView.bounds)
        dimmingView.image = self.presentingViewController.view.snapshotImage()?.applyDarkEffect()
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmingView.alpha = 0
        self.dimmingView = dimmingView
        containerView.addSubview(dimmingView)
        
        let presentationRoundedCornerView = UIView(frame: presentationWrapperView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -Constants.kCornerRadius, right: 0)))
        presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentationRoundedCornerView.layer.cornerRadius = Constants.kCornerRadius
        presentationRoundedCornerView.layer.masksToBounds = true
        
        // To undo the extra height added to presentationRoundedCornerView,
        // presentedViewControllerWrapperView is inset by CORNER_RADIUS points.
        // This also matches the size of presentedViewControllerWrapperView's
        // bounds to the size of -frameOfPresentedViewInContainerView.
        
        let presentedViewControllerWrapperView = UIView(frame: presentationRoundedCornerView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: Constants.kCornerRadius, right: 0)))
        presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add presentedViewControllerView -> presentedViewControllerWrapperView.
        presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
        presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
        
        // Add presentationRoundedCornerView -> presentationWrapperView.
        presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
        
        presentationWrapperView.addSubview(presentationRoundedCornerView)
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if container === self.presentedViewController {
            return container.preferredContentSize
        } else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerViewBounds = self.containerView?.bounds else {
            return CGRect()
        }
        
        let presentedViewContentSize = self.size(forChildContentContainer: self.presentedViewController, withParentContainerSize: containerViewBounds.size)
        
        // The presented view extends presentedViewContentSize.height points from
        // the bottom edge of the screen.
        var presentedViewControllerFrame = containerViewBounds
        presentedViewControllerFrame.size.height = presentedViewContentSize.height
        presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height
        return presentedViewControllerFrame
    }
    
    func viewAndFinalFrameFor(transitionContext: UIViewControllerContextTransitioning) -> (UIView, CGRect, Bool) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from) else {
                fatalError()
        }
        
        let _ = transitionContext.initialFrame(for: fromViewController)
        var fromViewFinalFrame = transitionContext.finalFrame(for: fromViewController)
        
        let containerView = transitionContext.containerView
        
        let isPresenting = fromViewController == self.presentingViewController
        
        if let toViewUnwrapped = transitionContext.view(forKey: .to) {
            containerView.addSubview(toViewUnwrapped)
            if let dragView = self.dragView {
                dragView.frame.origin = .zero
                dragView.frame.size = CGSize(width: containerView.bounds.width, height: dragView.bounds.height)
                toViewUnwrapped.addSubview(dragView)
            }
        }
        
        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to) else {
                fatalError()
            }
            
            var toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
            
            if #available(iOS 13.0, *) {
                toViewFinalFrame =  toViewFinalFrame.offsetBy(dx: 0, dy:  -toView.frame.height)
            }
            
            toView.frame = toView.frame.offsetBy(dx: 0, dy: toView.frame.height);

            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            tapGestureRecognizer.delegate = self
            transitionContext.containerView.addGestureRecognizer(tapGestureRecognizer)
            
            self.dismissInteractor = ViewControllerInteractiveTransition(viewController: presentedViewController, view: self.dragView)
            
            return (toView, toViewFinalFrame, isPresenting)
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else {
                fatalError()
            }
            
            fromViewFinalFrame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
            
            return (fromView, fromViewFinalFrame, isPresenting)
        }
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        self.presentingViewController.dismiss(animated: true, completion: nil)
    }
    
}

extension CustomPresentationController: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.kAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let (view, frame, isPresenting) = self.viewAndFinalFrameFor(transitionContext: transitionContext)
        
        UIView.animate(withDuration: Constants.kAnimationDuration, animations: {
            view.frame = frame
            self.dimmingView?.alpha = isPresenting ? 1 : 0
        }, completion: { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let propertyAnimator = self.propertyAnimator {
            return propertyAnimator
        }
        
        var timingParameters = UICubicTimingParameters(animationCurve: .easeInOut)
        if let dismissInteractor = self.dismissInteractor, dismissInteractor.isActive {
            timingParameters = UICubicTimingParameters(animationCurve: .linear)
        }
        
        let (view, frame, isPresenting) = self.viewAndFinalFrameFor(transitionContext: transitionContext)
        
        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext), timingParameters: timingParameters)
        animator.addAnimations {
            view.frame = frame
            self.dimmingView?.alpha = isPresenting ? 1 : 0
        }
        animator.addCompletion { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.propertyAnimator = nil
        }
        
        self.propertyAnimator = animator
        return animator
    }
    
}

extension CustomPresentationController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.dismissInteractor?.isActive ?? false {
            return self.dismissInteractor
        }
        return nil
    }
    
}

extension CustomPresentationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.location(in: gestureRecognizer.view).y < self.presentingViewController.view.bounds.height - self.presentationWrappingView.bounds.height
    }
    
}
