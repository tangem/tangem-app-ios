//
//  Bool+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Bool {
     static var iOS13: Bool {
         guard #available(iOS 14, *) else {
             // It's iOS 13 so return true.
             return true
         }
         // It's iOS 14 so return false.
         return false
     }
    
    static var iOS15: Bool {
        if #available(iOS 15, *) {
            return true
        } else {
            return false
        }
    }
 }
