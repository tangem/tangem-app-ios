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

    private lazy var sheetRegistry = FloatingSheetRegistry.default
    private let incomingActionRecorder = IncomingActionRecorder()
    private lazy var appOverlaysManager = AppOverlaysManager(sheetRegistry: sheetRegistry)

    private var appCoordinator: AppCoordinator?
    private var debugMenuPresenter: DebugMenuPresenter?
    private var isSceneStarted = false

    // MARK: - Lifecycle

    /// This method can be called during app close, so we have to move out the one-time initialization code outside.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let userActivities = connectionOptions.userActivities

        // Before the links the app was launched by are read: what answers a link is put in place by the app
        // coordinator, and a link read earlier than that would find nobody to keep it for the main screen.
        incomingActionRecorder.start()
        startApp(scene: scene, appCoordinatorOptions: .default)

        if !handleUrlContexts(connectionOptions.urlContexts) {
            handleActivities(userActivities)
        }

        appOverlaysManager.setup(with: scene)

        handleAppsFlyerActivities(userActivities)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appLockController.sceneDidEnterBackground()
        addLockViewIfNeeded(scene: scene)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        lockIfNeeded(scene: scene)
        hideLockView()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !isSceneStarted else { return }

        isSceneStarted = true

        PerformanceMonitorConfigurator.configureIfAvailable()
        AppsFlyerWrapper.shared.handleApplicationDidBecomeActive()
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
        sheetRegistry.registerAddTokenFlowFloatingSheets()
        sheetRegistry.registerAddTokenFlowRedesignedFloatingSheets()
        sheetRegistry.registerTangemPayWalletSelectorSheets()
        sheetRegistry.registerCollectiblesFloatingSheets()
        sheetRegistry.registerJointAccountFloatingSheets()
        sheetRegistry.registerCloreMigrationFloatingSheets()
        sheetRegistry.registerYieldModuleFloatingSheets()
        sheetRegistry.registerTokenDetailsActionsFloatingSheets()
        sheetRegistry.registerTransactionDetailsFloatingSheets()
        sheetRegistry.registerEarnModuleFloatingSheets()
        sheetRegistry.registerForYouAccountSelectorSheets()
        sheetRegistry.registerForYouAddFundsSheets()
        sheetRegistry.registerSendFloatingSheets()
        sheetRegistry.registerMarketsDialogueFloatingSheets()
        sheetRegistry.registerMarketsSearchFloatingSheets()
        sheetRegistry.registerMarketsRealAssetsFloatingSheets()
        sheetRegistry.registerTokensManagementFloatingSheets()
        sheetRegistry.registerRatingFloatingSheets()
        sheetRegistry.registerAddFundsFloatingSheets()
        sheetRegistry.registerPriceAlertsFloatingSheets()
        sheetRegistry.registerTokenSummaryFloatingSheets()
        sheetRegistry.registerPolymarketFloatingSheets()
        sheetRegistry.registerCampaignFloatingSheets()
        sheetRegistry.registerTangemPayTransactionDetailsFloatingSheets()

        let appCoordinator = AppCoordinator()
        let appCoordinatorView = AppCoordinatorView(coordinator: appCoordinator)
            .environment(\.floatingSheetRegistry, sheetRegistry)
            .mainWindowSize(initial: window.screen.bounds.size)

        window.rootViewController = UIHostingController(rootView: appCoordinatorView)
        appCoordinator.start(with: appCoordinatorOptions)
        self.appCoordinator = appCoordinator
        self.window = window
        appOverlaysManager.setMainWindow(window)
        window.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
        window.makeKeyAndVisible()

        setupDebugMenuIfNeeded(window: window)
    }

    private func setupDebugMenuIfNeeded(window: MainWindow) {
        guard !AppEnvironment.current.isProduction else { return }

        let presenter = DebugMenuPresenter()
        window.onShake = { [weak presenter] in
            presenter?.presentIfNeeded()
        }
        debugMenuPresenter = presenter
    }

    private func hideLockView() {
        lockWindow?.isHidden = true
        lockWindow = nil
    }

    // MARK: - Incoming actions

    /// Hot handle deeplinks `https://tangem.com, https://app.tangem.com`
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        lockIfNeeded(scene: scene)
        handleActivities([userActivity])
        handleAppsFlyerActivities([userActivity])
    }

    /// Hot handle universal links  with `tangem://` scheme
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        lockIfNeeded(scene: scene)
        handleUrlContexts(URLContexts)
    }

    /// Locks the app that has been in the background long enough, replacing the session with the locked
    /// coordinator. Called on the way to the foreground and when a link arrives: a link that brings the app
    /// back is delivered before the foreground transition, and a session about to be locked must not answer
    /// it — the coordinator that waits for the unlock must, so that it can show the link once unlocked.
    /// A coordinator already at the lock is kept, along with whatever link it holds.
    private func lockIfNeeded(scene: UIScene) {
        appLockController.sceneWillEnterForeground()

        guard let viewState = appCoordinator?.viewState, viewState.shouldAddLockView, appLockController.isLocked else {
            return
        }

        if case .lock = viewState {
            return
        }

        mainBottomSheetUIManager.hide()
        appOverlaysManager.forceDismiss()
        startApp(scene: scene, appCoordinatorOptions: .locked)
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

    private func handleAppsFlyerActivities(_ userActivities: Set<NSUserActivity>) {
        for activity in userActivities {
            AppsFlyerWrapper.shared.handleUserActivity(userActivity: activity)
        }
    }
}
