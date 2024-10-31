//
//  ViewHierarchySnapshotting.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Environment values

extension EnvironmentValues {
    var viewHierarchySnapshotter: ViewHierarchySnapshotting? {
        get { self[ViewHierarchySnapshotterEnvironmentKey.self] }
        set { self[ViewHierarchySnapshotterEnvironmentKey.self] = newValue }
    }
}

// MARK: - Private implementation

private enum ViewHierarchySnapshotterEnvironmentKey: EnvironmentKey {
    static var defaultValue: ViewHierarchySnapshotting? { nil }
}
