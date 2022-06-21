//
//  SceneCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SceneCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SceneCoordinator
    
    var body: some View {
        AppCoordinatorView(coordinator: coordinator.appCoordinator)
    }
}
