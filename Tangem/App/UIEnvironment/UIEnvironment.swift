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
    let shareActivitiesPresenter = ShareActivitiesViewModel()
}

private struct UIEnvironmentKey: InjectionKey {
    static var currentValue = UIEnvironment()
}

private extension InjectedValues {
    var environment: UIEnvironment {
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
    var floatingSheetPresenter: any FloatingSheetPresenter {
        environment.floatingSheetViewModel
    }

    var floatingSheetPresentingStateProvider: any FloatingSheetPresentingStateProvider {
        environment.floatingSheetViewModel
    }

    var alertPresenter: any AlertPresenter {
        environment.alertPresenter
    }

    var overlayShareActivitiesPresenter: any ShareActivitiesPresenter {
        environment.shareActivitiesPresenter
    }
}

// MARK: - AppOverlaysManager support

/// Provides separated namespace for `AppOverlaysManager` dependencies to avoid possible exposure.
struct AppOverlaysDependencies {
    fileprivate let injectedValues: InjectedValues

    fileprivate init(_ injectedValues: InjectedValues) {
        self.injectedValues = injectedValues
    }

    var floatingSheetViewModel: FloatingSheetViewModel {
        injectedValues.environment.floatingSheetViewModel
    }

    var overlayShareActivitiesViewModel: ShareActivitiesViewModel {
        injectedValues.environment.shareActivitiesPresenter
    }

    var alertPresenterViewModel: AlertPresenterViewModel {
        injectedValues.environment.alertPresenter
    }
}

extension InjectedValues {
    /// - Warning: Implementation details for `AppOverlaysManager`, do not use this property.
    @available(iOS, deprecated: 100000.0, message: "Implementation details for `AppOverlaysManager`, do not use this property.")
    var appOverlaysDependencies: AppOverlaysDependencies { .init(self) }
}
