//
//  MarketsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root Published

    @Published private(set) var rootViewModel: MarketsViewModel?

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Helpers

    let viewHierarchySnapshotter: UIViewController
    private let viewHierarchySnapshottingAdapter: ViewHierarchySnapshotting

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        let viewHierarchySnapshotter = ViewHierarchySnapshottingContainerViewController()
        viewHierarchySnapshotter.shouldPropagateOverriddenUserInterfaceStyleToChildren = true
        viewHierarchySnapshottingAdapter = ViewHierarchySnapshottingWeakifyAdapter(adaptee: viewHierarchySnapshotter)
        self.viewHierarchySnapshotter = viewHierarchySnapshotter
    }

    // MARK: - Implementation

    func start(with options: MarketsCoordinator.Options) {
        rootViewModel = .init(
            quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
            viewHierarchySnapshotter: viewHierarchySnapshottingAdapter,
            coordinator: self
        )
    }
}

extension MarketsCoordinator {
    struct Options {}
}

extension MarketsCoordinator: MarketsRoutable {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        marketsListOrderBottomSheetViewModel = .init(from: provider, onDismiss: { [weak self] in
            self?.marketsListOrderBottomSheetViewModel = nil
        })
    }

    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        let tokenDetailsCoordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )
        tokenDetailsCoordinator.start(with: .init(info: tokenInfo, style: .marketsSheet))

        self.tokenDetailsCoordinator = tokenDetailsCoordinator
    }
}
