//
//  KeyboardHeightPublisher.swift
//  KeyboardAvoidanceSwiftUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Vadim Bulavin. All rights reserved.
//

import Combine
import UIKit

extension Publishers {
    static var keyboardInfo: AnyPublisher<(CGFloat, Double), Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { ($0.keyboardHeight, $0.anumationDuration) }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { (CGFloat(0), $0.anumationDuration) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
    
    var anumationDuration: Double {
        return (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
    }
    
}
