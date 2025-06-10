//
//  ViewHierarchySnapshottingContainerViewControllerAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class ViewHierarchySnapshottingContainerViewControllerAdapter {
    private weak var viewHierarchySnapshotter: ViewHierarchySnapshotting?
}

extension ViewHierarchySnapshottingContainerViewControllerAdapter: ViewHierarchySnapshottingInitializable {
    func set(_ viewHierarchySnapshotter: any ViewHierarchySnapshotting) {
        self.viewHierarchySnapshotter = viewHierarchySnapshotter
    }
}

// MARK: - ViewHierarchySnapshotting protocol conformance

extension ViewHierarchySnapshottingContainerViewControllerAdapter: ViewHierarchySnapshotting {
    func makeSnapshotView(afterScreenUpdates: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIView? {
        viewHierarchySnapshotter?.makeSnapshotView(afterScreenUpdates: afterScreenUpdates, overrideUserInterfaceStyle: overrideUserInterfaceStyle)
    }

    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIImage? {
        viewHierarchySnapshotter?.makeSnapshotViewImage(
            afterScreenUpdates: afterScreenUpdates,
            isOpaque: isOpaque,
            overrideUserInterfaceStyle: overrideUserInterfaceStyle
        )
    }

    func makeSnapshotLayerImage(options: CALayerSnapshotOptions, isOpaque: Bool) -> UIImage? {
        viewHierarchySnapshotter?.makeSnapshotLayerImage(options: options, isOpaque: isOpaque)
    }
}
