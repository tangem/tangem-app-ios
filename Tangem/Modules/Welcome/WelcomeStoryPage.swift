//
//  WelcomeStoryPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WelcomeStoryPage: Int, Identifiable, CaseIterable {
    var id: Int {
        rawValue
    }

    case meetTangem
    case awe
    case backup
    case currencies
    // case web3
    case finish

    var colorScheme: ColorScheme {
        switch self {
        case .meetTangem, .awe, .finish:
            return .dark
        default:
            return .light
        }
    }

    var duration: Double {
        switch self {
        case .meetTangem:
            return 8
        default:
            return 6
        }
    }
}
