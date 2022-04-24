//
//  ViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol ViewModel: Identifiable, ViewModelNavigatable {
    var assembly: Assembly! { get set }
}

protocol ViewModelNavigatable: AnyObject {
    var navigation: NavigationCoordinator! { get set }
}
