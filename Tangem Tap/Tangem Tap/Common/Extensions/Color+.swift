//
//  Color+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    @nonobjc static var tangemTapBlue: Color {
        return Color("tangem_tap_blue")
    }
    
    @nonobjc static var tangemTapBlack: Color {
        return Color("tangem_tap_black")
    }
    
    @nonobjc static var tangemTapTitle: Color {
        return Color("tangem_tap_title")
    }
    
    @nonobjc static var tangemTapLightGray: Color {
        return Color("tangem_tap_lightGray")
    }
    
    @nonobjc static var tangemTapGreen: Color {
        return Color("tangem_tap_green")
    }
    
    @nonobjc static var tangemBg: Color {
        return Color("tangem_bg")
    }
    
    @nonobjc static var tangemTapYellow: Color {
         return Color("tangem_tap_yellow")
    }
    
    @nonobjc static var tangemTapDarkGrey: Color {
         return Color("tangem_tap_dark_grey")
    }
    
    @nonobjc static var tangemTapBgGray: Color {
           return Color("tangem_tap_bgGray")
      }
}

extension UIColor {
    @nonobjc static var tangemTapBgGray: UIColor {
        return UIColor(named: "tangem_tap_bgGray")!
    }
}
