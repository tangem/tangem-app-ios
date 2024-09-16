//
//  ViewHierarchySnapshottingWeakifyAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class ViewHierarchySnapshottingWeakifyAdapter {
    typealias Adaptee = ViewHierarchySnapshotting & AnyObject

    private weak var adaptee: Adaptee?

    init(adaptee: Adaptee?) {
        self.adaptee = adaptee
    }
}

// MARK: - ViewHierarchySnapshotting protocol conformance

extension ViewHierarchySnapshottingWeakifyAdapter: ViewHierarchySnapshotting {
    func makeSnapshotView(afterScreenUpdates: Bool) -> UIView? {
        adaptee?.makeSnapshotView(afterScreenUpdates: afterScreenUpdates)
    }

    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool) -> UIImage? {
        adaptee?.makeSnapshotViewImage(afterScreenUpdates: afterScreenUpdates, isOpaque: isOpaque)
    }

    func makeSnapshotLayerImage(options: CALayerSnapshotOptions, isOpaque: Bool) -> UIImage? {
        adaptee?.makeSnapshotLayerImage(options: options, isOpaque: isOpaque)
    }
}
