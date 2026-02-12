//
//  DesignSystemDemoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class DesignSystemDemoViewModel: ObservableObject {
    weak var coordinator: DesignSystemDemoRoutable?

    init(coordinator: DesignSystemDemoRoutable) {
        self.coordinator = coordinator
    }

    func openTypo() {
        coordinator?.openTypography()
    }

    func openButtons() {
        coordinator?.openButtons()
    }
}
