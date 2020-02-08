//
//  UIViewExtensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

extension UIView {
    
    public class func gb_nibUsingClassName() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    public class func gb_loadFromDefaultNib() -> Self? {
        guard let view = self.gb_nibUsingClassName().instantiate(withOwner: nil, options: nil).first as? UIView else {
            return nil
        }
        return unsafeDowncast(view, to: self)
    }
    
}

extension UIButton {
    public func showActivityIndicator() {
        let views = subviews.filter{ $0 is UIActivityIndicatorView }
        guard views.isEmpty else { return }
        
        isEnabled = false
    
        imageView?.isHidden = true
        imageView?.setNeedsLayout()
        fadeTransition(0.15)
        let activityIndicator = createActivityIndicator()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        activityIndicator.color = (backgroundColor == UIColor.white || backgroundColor == UIColor.clear) ? .darkGray : .white
        centerActivityIndicatorInButton(activityIndicator: activityIndicator)
        setTitleColor(UIColor.clear, for: .normal)
        setTitleColor(UIColor.clear, for: .highlighted)
        setTitleColor(UIColor.clear, for: .disabled)
        activityIndicator.startAnimating()
    }
    
    public func hideActivityIndicator() {
        let activityArray = subviews.filter{ $0 is UIActivityIndicatorView }
         imageView?.isHidden = false
         imageView?.setNeedsLayout()
        var textColor : UIColor?
        for each in activityArray {
            guard let activity = each as? UIActivityIndicatorView else { continue }
            
            activity.stopAnimating()
            activity.removeFromSuperview()
        }
        isEnabled = true
        fadeTransition(0.15)
        textColor = (backgroundColor == UIColor.white || backgroundColor == UIColor.clear) ? .black : .white
        setTitleColor(textColor, for: .normal)
        setTitleColor(UIColor.gray, for: .highlighted)
        setTitleColor(UIColor.lightGray, for: .disabled)
    }
}

extension UILabel {
    public func showActivityIndicator() {
        let views = subviews.filter{ $0 is UIActivityIndicatorView }
        guard views.isEmpty else { return }
        //isEnabled = false
        fadeTransition(0.15)
        let activityIndicator = createActivityIndicator()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        activityIndicator.color = .darkGray
        centerActivityIndicatorInButton(activityIndicator: activityIndicator)
        textColor = .clear
        activityIndicator.startAnimating()
    }
    
    public func hideActivityIndicator() {
        let activityArray = subviews.filter{ $0 is UIActivityIndicatorView }
        
        var foundIndicator = false
        for each in activityArray {
            guard let activity = each as? UIActivityIndicatorView else { continue }
            foundIndicator = true
            activity.stopAnimating()
            activity.removeFromSuperview()
        }
        guard foundIndicator else {
            return
        }
       //isEnabled = true
        fadeTransition(0.15)
        textColor = .lightGray
    }
}

extension UIView {
        func createActivityIndicator() -> UIActivityIndicatorView {
           let activityIndicator = UIActivityIndicatorView()
           activityIndicator.hidesWhenStopped = true
           activityIndicator.color = UIColor.white
           return activityIndicator
       }
       
        func centerActivityIndicatorInButton(activityIndicator : UIActivityIndicatorView) {
           let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
           self.addConstraint(xCenterConstraint)
           let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
           self.addConstraint(yCenterConstraint)
       }
       
        func fadeTransition(_ duration: CFTimeInterval) {
           let animation:CATransition = CATransition()
           animation.timingFunction =  CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
           animation.type = kCATransitionFade
           animation.duration = duration
           self.layer.add(animation, forKey: kCATransitionFade)
       }
}
