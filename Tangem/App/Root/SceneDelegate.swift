//
//  SceneDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk
import class TangemUI.FloatingSheetRegistry
import BlockchainSdk
import TangemUIUtils
import TangemFoundation

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler
    @Injected(\.appLockController) private var appLockController: AppLockController
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    var window: UIWindow?
    var lockWindow: UIWindow?

    private lazy var sheetRegistry = FloatingSheetRegistry()
    private lazy var appOverlaysManager = AppOverlaysManager(sheetRegistry: sheetRegistry)

    private var appCoordinator: AppCoordinator?
    private var isSceneStarted = false

    // MARK: - Lifecycle

    /// This method can be called during app close, so we have to move out the one-time initialization code outside.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if !handleUrlContexts(connectionOptions.urlContexts) {
            handleActivities(connectionOptions.userActivities)
        }

        startApp(scene: scene, appCoordinatorOptions: .default)
        appOverlaysManager.setup(with: scene)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appLockController.sceneDidEnterBackground()
        addLockViewIfNeeded(scene: scene)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        appLockController.sceneWillEnterForeground()

        guard appCoordinator?.viewState?.shouldAddLockView ?? false else {
            hideLockView()
            return
        }

        if appLockController.isLocked {
            mainBottomSheetUIManager.hide(shouldUpdateFooterSnapshot: false)
            appOverlaysManager.forceDismiss()
            startApp(scene: scene, appCoordinatorOptions: .locked)
            hideLockView()
        } else {
            hideLockView()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !isSceneStarted else { return }

        isSceneStarted = true

        PerformanceMonitorConfigurator.configureIfAvailable()
        AppsFlyerConfigurator.handleApplicationDidBecomeActive()
    }

    /// Additional view to fix no-refresh in bg issue for iOS prior to 17.
    /// Just keep this code to unify behavior between different ios versions
    private func addLockViewIfNeeded(scene: UIScene) {
        guard appCoordinator?.viewState?.shouldAddLockView == true,
              let windowScene = scene as? UIWindowScene else {
            return
        }

        let lockWindow = UIWindow(windowScene: windowScene)
        lockWindow.rootViewController = UIHostingController(rootView: LockView(usesNamespace: false))
        lockWindow.windowLevel = .alert + 1
        lockWindow.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
        self.lockWindow = lockWindow
        lockWindow.makeKeyAndVisible()
    }

    private func startApp(scene: UIScene, appCoordinatorOptions: AppCoordinator.Options) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = MainWindow(windowScene: windowScene)

        sheetRegistry.registerWalletConnectFloatingSheets()
        sheetRegistry.registerAccountsAwareAddTokenFlowFloatingSheets()
        sheetRegistry.registerTangemPayWalletSelectorSheets()

        let appCoordinator = AppCoordinator()
        let appCoordinatorView = AppCoordinatorView(coordinator: appCoordinator).environment(\.floatingSheetRegistry, sheetRegistry)

        let factory = RootViewControllerFactory()
        let rootViewController = factory.makeRootViewController(
            for: appCoordinatorView,
            coordinator: appCoordinator,
            window: window
        )
        window.rootViewController = rootViewController
        appCoordinator.start(with: appCoordinatorOptions)
        self.appCoordinator = appCoordinator
        self.window = window
        appOverlaysManager.setMainWindow(window)
        window.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
        window.makeKeyAndVisible()
    }

    private func hideLockView() {
        lockWindow?.isHidden = true
        lockWindow = nil
    }

    // MARK: - Incoming actions

    /// Hot handle deeplinks `https://tangem.com, https://app.tangem.com`
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleActivities([userActivity])
    }

    /// Hot handle universal links  with `tangem://` scheme
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleUrlContexts(URLContexts)
    }

    @discardableResult
    private func handleActivities(_ userActivities: Set<NSUserActivity>) -> Bool {
        for activity in userActivities {
            switch activity.activityType {
            case NSUserActivityTypeBrowsingWeb:
                if let url = activity.webpageURL {
                    if incomingActionHandler.handleIncomingURL(url) {
                        return true
                    }
                }

            default:
                if incomingActionHandler.handleIntent(activity.activityType) {
                    return true
                }
            }
        }

        return false
    }

    @discardableResult
    private func handleUrlContexts(_ urlContexts: Set<UIOpenURLContext>) -> Bool {
        for context in urlContexts {
            if incomingActionHandler.handleIncomingURL(context.url) {
                return true
            }
        }

        return false
    }
}
