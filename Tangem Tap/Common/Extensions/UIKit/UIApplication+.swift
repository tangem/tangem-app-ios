//
//  UIApplication+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        windows.first { $0.isKeyWindow }?.endEditing(true)
    }
}

extension UIApplication {
    static var topViewController : UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return keyWindow?.topViewController
    }
    
    static func modalFromTop(_ vc: UIViewController) {
        guard let top = topViewController else { return }
        
        top.present(vc, animated: true, completion: nil)
    }
}
