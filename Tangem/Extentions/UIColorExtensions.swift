//
//  UIColorExtensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import Foundation

extension UIColor {
    
    // MARK: Helpers
    
    public class func tgm_rgb(red: Int, green: Int, blue: Int) -> UIColor {
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
    }
    
    public class func tgm_grayscale(white: Int) -> UIColor {
        return UIColor(red: CGFloat(white) / 255.0, green: CGFloat(white) / 255.0, blue: CGFloat(white) / 255.0, alpha: 1)
    }
    
    public class func tgm_grayscale(white: Int, alpha: CGFloat) -> UIColor {
        return UIColor(red: CGFloat(white) / 255.0, green: CGFloat(white) / 255.0, blue: CGFloat(white) / 255.0, alpha: alpha)
    }
    
    // MARK: Colors
    
    static func tgm_green() -> UIColor {
        return self.tgm_rgb(red: 0x0, green: 0xDB, blue: 0x18)
    }
    
    static func tgm_red() -> UIColor {
        return self.tgm_rgb(red: 0xFF, green: 0x53, blue: 0x72)
    }
    
}
