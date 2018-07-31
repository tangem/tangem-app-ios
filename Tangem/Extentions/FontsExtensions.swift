//
//  FontsExtensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import UIKit

extension UIFont {
    
    /*
     - 2 : "Maax"
     - 5 : "Maax-Medium"
     - 4 : "Maax-Bold"
     - 0 : "Maax-Black"
     
     - 6 : "Maax-Italic"
     - 3 : "Maax-Mediumitalic"
     - 1 : "Maax-BoldItalic"
     
     
     - 5 : "SairaCondensed-Regular"
     - 8 : "SairaCondensed-Medium"
     - 7 : "SairaCondensed-SemiBold"
     - 2 : "SairaCondensed-Bold"
     - 6 : "SairaCondensed-ExtraBold"
     - 1 : "SairaCondensed-Black"
     
     - 0 : "SairaCondensed-Light"
     - 4 : "SairaCondensed-Thin"
     - 3 : "SairaCondensed-ExtraLight"

     */
    
    static func tgm_sairaFontWith(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        var name = "SairaCondensed-Regular"
        
        switch weight {
        case .medium:
            name = "SairaCondensed-Medium"
        case .bold:
            name = "SairaCondensed-Bold"
        case .black:
            name = "SairaCondensed-Black"
        case .semibold:
            name = "SairaCondensed-SemiBold"
        case .heavy:
            name = "SairaCondensed-ExtraBold"
        case .light:
            name = "SairaCondensed-Light"
        case .thin:
            name = "SairaCondensed-Thin"
        case .ultraLight:
            name = "SairaCondensed-ExtraLight"
        default:
            name = "SairaCondensed-Regular"
        }
        
        guard let font = UIFont(name: name, size: size) else {
            assertionFailure()
            return UIFont.systemFont(ofSize: size)
        }
        
        return font
    }
    
    static func tgm_maaxFontWith(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        var name = "Maax"
        
        switch weight {
        case .medium:
            name = "Maax-Medium"
        case .bold:
            name = "Maax-Bold"
        case .black:
            name = "Maax-Black"
        default:
            name = "Maax"
        }
        
        guard let font = UIFont(name: name, size: size) else {
            assertionFailure()
            return UIFont.systemFont(ofSize: size)
        }
        
        return font
    }
    
    static func tgm_maaxItalicFontWith(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        var name = "Maax-Italic"
        
        switch weight {
        case .medium:
            name = "Maax-Mediumitalic"
        case .bold:
            name = "Maax-BoldItalic"
        default:
            name = "Maax-Italic"
        }
        
        guard let font = UIFont(name: name, size: size) else {
            assertionFailure()
            return UIFont.systemFont(ofSize: size)
        }
        
        return font
    }
    
}
