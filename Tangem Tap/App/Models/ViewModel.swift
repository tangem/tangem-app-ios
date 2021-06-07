//
//  ViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol ViewModel: ObservableObject, Identifiable, ViewModelNavigatable {
    var assembly: Assembly! { get set }
}

protocol ViewModelNavigatable: AnyObject {
    var navigation: NavigationCoordinator! { get set }
}
