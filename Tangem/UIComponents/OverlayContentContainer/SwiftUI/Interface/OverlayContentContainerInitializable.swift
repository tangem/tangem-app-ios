//
//  OverlayContentContainerInitializable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Interface that initializes `OverlayContentContainerViewControllerAdapter`'
protocol OverlayContentContainerInitializable: AnyObject {
    func set(_ containerViewController: OverlayContentContainerViewController)
}
