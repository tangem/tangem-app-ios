//
//  ViewHierarchySnapshottingInitializable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Interface that initializes `OverlayContentContainerViewControllerAdapter`'
protocol ViewHierarchySnapshottingInitializable: AnyObject {
    func set(_ viewHierarchySnapshotter: ViewHierarchySnapshotting)
}
