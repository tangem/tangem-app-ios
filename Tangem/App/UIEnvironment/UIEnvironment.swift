//
//  UIEnvironment.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

private final class UIEnvironment {
    let overlayContentAdapter = OverlayContentContainerViewControllerAdapter()
    let viewHierarchySnapshottingAdapter = ViewHierarchySnapshottingContainerViewControllerAdapter()
    let floatingSheetViewModel = FloatingSheetViewModel()
    let alertPresenter = AlertPresenterViewModel()
}

private struct UIEnvironmentKey: InjectionKey {
    static var currentValue = UIEnvironment()
}

extension InjectedValues {
    private var environment: UIEnvironment {
        get { Self[UIEnvironmentKey.self] }
        set { Self[UIEnvironmentKey.self] = newValue }
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

// MARK: - Floating sheet

extension InjectedValues {
    var floatingSheetViewModel: FloatingSheetViewModel {
        environment.floatingSheetViewModel
    }

    var floatingSheetPresenter: any FloatingSheetPresenter {
        environment.floatingSheetViewModel
    }

    var alertPresenterViewModel: AlertPresenterViewModel {
        environment.alertPresenter
    }

    var alertPresenter: any AlertPresenter {
        environment.alertPresenter
    }
}
