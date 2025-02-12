//
//  UIEnvironment.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol UIEnvironment {
    var overlayContentAdapter: OverlayContentContainerViewControllerAdapter { get }
    var viewHierarchySnapshottingAdapter: ViewHierarchySnapshottingContainerViewControllerAdapter { get }
}

private struct UIEnvironmenteKey: InjectionKey {
    static var currentValue: UIEnvironment = CommonUIEnvironment()
}

extension InjectedValues {
    private var environment: UIEnvironment {
        get { Self[UIEnvironmenteKey.self] }
        set { Self[UIEnvironmenteKey.self] = newValue }
    }
}

// MARK: - Overlay

extension InjectedValues {
    var overlayContentContainerInitializer: OverlayContentContainerInitializable {
        environment.overlayContentAdapter
    }

    var overlayContentContainer: OverlayContentContainer {
        environment.overlayContentAdapter
    }

    var overlayContentStateObserver: OverlayContentStateObserver {
        environment.overlayContentAdapter
    }

    var overlayContentStateController: OverlayContentStateController {
        environment.overlayContentAdapter
    }
}

// MARK: - ViewHierarchySnapshotting

extension InjectedValues {
    var viewHierarchySnapshotter: ViewHierarchySnapshotting {
        environment.viewHierarchySnapshottingAdapter
    }

    var viewHierarchySnapshotterInitializer: ViewHierarchySnapshottingInitializable {
        environment.viewHierarchySnapshottingAdapter
    }
}
