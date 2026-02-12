//
//  AuthCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct AuthCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AuthCoordinator

    private var geometryEffect: GeometryEffectPropertiesModel?

    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack {
            content
        }
    }

    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AuthView(viewModel: rootViewModel)
            }
        }
    }
}

extension AuthCoordinatorView: Setupable {
    func setGeometryEffect(_ geometryEffect: GeometryEffectPropertiesModel) -> Self {
        map { $0.geometryEffect = geometryEffect }
    }
}
