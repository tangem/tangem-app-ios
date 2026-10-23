//
//  SnapshotCanvas.swift
//  TangemSnapshotTestSupport
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

public enum SnapshotCanvas: Sendable {
    case component
    case screen(SnapshotDevice)
    case fixed(width: CGFloat, height: CGFloat)
}
