//
//  WelcomeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WelcomeStep {
    case welcome, letsStart
    
    var title: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding_read_title"
        case .letsStart: return "onboarding_read_title"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding_read_subtitle"
        case .letsStart: return "onboarding_read_subtitle"
        }
    }
    
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return "home_button_scan"
        case .letsStart: return "home_button_scan"
        }
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return "onboarding_button_shop"
        case .letsStart: return "onboarding_button_shop"
        }
    }
}
