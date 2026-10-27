//
//  SnapshotDevice.swift
//  TangemSnapshotTestSupport
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import UIKit

public enum SnapshotDevice: String, CaseIterable, Sendable {
    case compact
    case regular
    case large

    var config: ViewImageConfig {
        switch self {
        case .compact:
            .iPhone8
        case .regular:
            ViewImageConfig(
                safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
                size: CGSize(width: 402, height: 874),
                traits: .iPhone13(.portrait)
            )
        case .large:
            ViewImageConfig(
                safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
                size: CGSize(width: 440, height: 956),
                traits: .iPhone13ProMax(.portrait)
            )
        }
    }

    var scale: CGFloat {
        switch self {
        case .compact: 2
        case .regular, .large: 3
        }
    }
}
