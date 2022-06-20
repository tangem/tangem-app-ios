//
//  AppServiceCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppServiceCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppServiceCoordinator
    
    var body: some View {
        AppCoordinatorView(coordinator: coordinator.appCoordinator)
    }
}
