import Foundation
import UIKit

public extension UIView {
    func nextKeyboardResponder() -> UIView? {
        let keyViews = sortedKeyViews()
        let current = findFirstResponder()
        if let index = (keyViews.firstIndex { $0 == current }) {
            let nextIndex = (index + 1) % keyViews.count
            return keyViews[nextIndex]
        }
        return keyViews.first
        
    }
    
    func prevKeyboardResponder() -> UIView? {
        let keyViews = sortedKeyViews()
        let current = findFirstResponder()
        if let index = (keyViews.firstIndex { $0 == current }) {
            let nextIndex = (index + keyViews.count - 1) % keyViews.count
            return keyViews[nextIndex]
        }
        return keyViews.first
    }
}

extension UIView {
    func requiresKeyboard() -> Bool {
        guard self is UIKeyInput else { return false }
        if responds(to: #selector(getter: UITextView.isEditable)) {
            let isEditable = value(forKey: "isEditable") as? Bool
            if isEditable == false {
                return false
            }
        }
        return true
    }
    
    func collectKeyViews() -> [UIView] {
        var keyViews = [UIView]()
        if requiresKeyboard()  {
            if canBecomeFirstResponder {
                keyViews.append(self)
            }
        } else {
            keyViews.append(contentsOf: subviews.flatMap { $0.collectKeyViews() })
        }
        return keyViews
    }
    
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        for subview in subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        return nil
    }
    
    func sortedKeyViews() -> [UIView] {
        return collectKeyViews().sorted { [weak self] left, right in
            let leftOrigin = left.convert(left.bounds.origin, to:self)
            let rightOrigin = right.convert(right.frame.origin, to:self)
            if leftOrigin.y != rightOrigin.y {
                return leftOrigin.y < rightOrigin.y
            }
            return leftOrigin.x < rightOrigin.x
        }
    }
}
