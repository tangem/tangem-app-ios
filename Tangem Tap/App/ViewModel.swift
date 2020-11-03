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

protocol ViewModel: ObservableObject {
    var navigation: NavigationCoordinator! {get set}
    var assembly: Assembly! {get set}
}
