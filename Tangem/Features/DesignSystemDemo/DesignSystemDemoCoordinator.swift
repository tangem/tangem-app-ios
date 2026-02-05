//
//  DesignSystemDemoCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

protocol DesignSystemDemoRoutable: AnyObject {
    func openTypography()
}

final class DesignSystemDemoCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: DesignSystemDemoViewModel?
    @Published var typoCoordinator: TypographyDemoCoordinator?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        rootViewModel = .init(coordinator: self)
    }

    func start(with options: Void) {}
}

extension DesignSystemDemoCoordinator: DesignSystemDemoRoutable {
    func openTypography() {
        typoCoordinator = .init(
            dismissAction: { [weak self] _ in self?.typoCoordinator = nil },
            popToRootAction: { [weak self] _ in self?.typoCoordinator = nil }
        )

        typoCoordinator?.start(with: ())
    }
}

extension DesignSystemDemoCoordinator {
    struct Options {}
    typealias DismissOptions = Void
}
