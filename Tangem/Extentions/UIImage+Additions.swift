//
//  UIImage+Additions.swift
//  Haptic
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Gennady Berezovsky. All rights reserved.
//

import UIKit

@objc public extension UIView {
    
    @objc public func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
    
}
