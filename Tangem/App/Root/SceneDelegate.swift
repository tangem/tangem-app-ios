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
import Kingfisher
import TangemUI
import TangemFoundation

final class TangemAppObject: ObservableObject {
    @Injected(\.incomingActionHandler) var incomingActionHandler: IncomingActionHandler
    @Injected(\.appLockController) var appLockController: AppLockController
    @Injected(\.mainBottomSheetUIManager) var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.floatingSheetViewModel) var floatingSheetViewModel: FloatingSheetViewModel
    @Injected(\.tangemStoriesViewModel) var tangemStoriesViewModel: TangemStoriesViewModel
    @Injected(\.alertPresenterViewModel) var alertPresenterViewModel: AlertPresenterViewModel
    @Injected(\.storyKingfisherImageCache) var storyKingfisherImageCache: ImageCache

    let sheetRegistry = FloatingSheetRegistry()
}

@main
struct MainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Injected(\.floatingSheetViewModel)
    @ObservedObject
    var floatingSheetViewModel: FloatingSheetViewModel

    @ObservedObject private var appObject = TangemAppObject()
    @ObservedObject private var appCoordinator = AppCoordinator()

    @State private var alert: AlertBinder?
    @State private var actionSheet: ActionSheetBinder?
    @State private var floatingSheetHostingController: UIHostingController<AnyView>?
//    [REDACTED_USERNAME] private var floatingSheet: (any FloatingSheetContentViewModel)?

    ///    private var appOverlaysManager = AppOverlaysManager(sheetRegistry: appObject.sheetRegistry)
    private var servicesManager = KeychainSensitiveServicesManager()

    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler
    @Injected(\.appLockController) private var appLockController: AppLockController
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    @State private var lockWindow: UIWindow?

    init() {
        print("->> App is init")
    }

    var body: some Scene {
        WindowGroup(id: "Main") {
            ZStack {
                AppCoordinatorView(coordinator: appCoordinator)
                    .task {
                        await servicesManager.initialize()
                        startApp(options: .default)
                    }
                    .onOpenURL { url in
                        _ = incomingActionHandler.handleIncomingURL(url)
                    }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                        if let url = activity.webpageURL {
                            _ = incomingActionHandler.handleIncomingURL(url)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIScene.didEnterBackgroundNotification)) { _ in
                        appLockController.sceneDidEnterBackground()
                        addLockViewIfNeeded()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)) { _ in
                        appLockController.sceneWillEnterForeground()
                        handleForeground()
                    }

//                if #available(iOS 16, *) {
//                    OverlayRootView(
//                        floatingSheetViewModel: appObject.floatingSheetViewModel,
//                        tangemStoriesViewModel: appObject.tangemStoriesViewModel,
//                        alertPresenterViewModel: appObject.alertPresenterViewModel
//                    )
//                }
            }
            .onReceive(appObject.floatingSheetViewModel.$activeSheet, perform: { sheet in
                if sheet != nil {
                    let rootView = OverlayRootView(
                        floatingSheetViewModel: appObject.floatingSheetViewModel,
                        tangemStoriesViewModel: appObject.tangemStoriesViewModel,
                        alertPresenterViewModel: appObject.alertPresenterViewModel
                    )
                    .environment(\.floatingSheetRegistry, appObject.sheetRegistry)

                    let controller = UIHostingController(rootView: AnyView(rootView))
                    controller.view.backgroundColor = .orange.withAlphaComponent(0.1)
                    controller.modalPresentationStyle = .overFullScreen
                    floatingSheetHostingController = controller
                    UIApplication.topViewController?.present(floatingSheetHostingController!, animated: false)
                } else {
                    floatingSheetHostingController?.dismiss(animated: false)
                }
            })
            .onReceive(appObject.alertPresenterViewModel.$alert, perform: { alert = $0 })
            .onReceive(appObject.alertPresenterViewModel.$actionSheet, perform: { actionSheet = $0 })
            .alert(item: $alert) { $0.alert }
            .actionSheet(item: $actionSheet) { $0.sheet }
        }
        .environment(\.floatingSheetRegistry, appObject.sheetRegistry)
    }

    // MARK: - App lifecycle

    private func startApp(options: AppCoordinator.Options) {
        appCoordinator.start(with: options)
    }

    private func handleForeground() {
        guard appCoordinator.viewState?.shouldAddLockView ?? false else {
            hideLockView()
            return
        }

        if appLockController.isLocked {
            mainBottomSheetUIManager.hide(shouldUpdateFooterSnapshot: false)
            startApp(options: .locked)
            hideLockView()
        } else {
            hideLockView()
        }
    }

    // MARK: - Overlay UIWindow logic

    private func addLockViewIfNeeded() {
        guard appCoordinator.viewState?.shouldAddLockView == true,
              let windowScene = UIApplication.shared.connectedScenes
              .compactMap({ $0 as? UIWindowScene })
              .first else {
            return
        }

        let overlay = UIWindow(windowScene: windowScene)
        overlay.rootViewController = UIHostingController(rootView: LockView(usesNamespace: false))
        overlay.windowLevel = .alert + 1
        overlay.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
        overlay.makeKeyAndVisible()

        lockWindow = overlay
    }

    private func hideLockView() {
        lockWindow?.isHidden = true
        lockWindow = nil
    }
}

//
// final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//    [REDACTED_USERNAME](\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler
//    [REDACTED_USERNAME](\.appLockController) private var appLockController: AppLockController
//    [REDACTED_USERNAME](\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
//
//    var window: UIWindow?
//    var lockWindow: UIWindow?
//
//    private lazy var servicesManager = KeychainSensitiveServicesManager()
//    private lazy var sheetRegistry = FloatingSheetRegistry()
//    private lazy var appOverlaysManager = AppOverlaysManager(sheetRegistry: sheetRegistry)
//
//    private var appCoordinator: AppCoordinator?
////    private var isSceneStarted = false
//
//    // MARK: - Lifecycle
//
//    /// This method can be called during app close, so we have to move out the one-time initialization code outside.
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        if !handleUrlContexts(connectionOptions.urlContexts) {
//            handleActivities(connectionOptions.userActivities)
//        }
//
//        runTask(in: self) { delegate in
//            await delegate.servicesManager.initialize()
//
//            runOnMain {
//                delegate.startApp(scene: scene, appCoordinatorOptions: .default)
//                delegate.appOverlaysManager.setup(with: scene)
//            }
//        }
//    }
//
//    func sceneDidEnterBackground(_ scene: UIScene) {
//        appLockController.sceneDidEnterBackground()
//        addLockViewIfNeeded(scene: scene)
//    }
//
//    func sceneWillEnterForeground(_ scene: UIScene) {
//        appLockController.sceneWillEnterForeground()
//
//        guard appCoordinator?.viewState?.shouldAddLockView ?? false else {
//            hideLockView()
//            return
//        }
//
//        if appLockController.isLocked {
//            mainBottomSheetUIManager.hide(shouldUpdateFooterSnapshot: false)
////            appOverlaysManager.forceDismiss()
//            startApp(scene: scene, appCoordinatorOptions: .locked)
//            hideLockView()
//        } else {
//            hideLockView()
//        }
//    }
//
//    func sceneDidBecomeActive(_ scene: UIScene) {
////        guard !isSceneStarted else { return }
//
////        isSceneStarted = true
//
//        PerformanceMonitorConfigurator.configureIfAvailable()
//
////        guard AppEnvironment.current.isProduction else { return }
//    }
//
//    /// Additional view to fix no-refresh in bg issue for iOS prior to 17.
//    /// Just keep this code to unify behavior between different ios versions
//    private func addLockViewIfNeeded(scene: UIScene) {
//        guard appCoordinator?.viewState?.shouldAddLockView == true,
//              let windowScene = scene as? UIWindowScene else {
//            return
//        }
//
//        let lockWindow = UIWindow(windowScene: windowScene)
//        lockWindow.rootViewController = UIHostingController(rootView: LockView(usesNamespace: false))
//        lockWindow.windowLevel = .alert + 1
//        lockWindow.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
//        self.lockWindow = lockWindow
//        lockWindow.makeKeyAndVisible()
//    }
//
//    private func startApp(scene: UIScene, appCoordinatorOptions: AppCoordinator.Options) {
//        guard let windowScene = scene as? UIWindowScene else {
//            return
//        }
//
//        let window = MainWindow(windowScene: windowScene)
//        let appCoordinator = AppCoordinator()
//        let appCoordinatorView = AppCoordinatorView(coordinator: appCoordinator).environment(\.floatingSheetRegistry, sheetRegistry)
//        let factory = RootViewControllerFactory()
//        let rootViewController = factory.makeRootViewController(
//            for: appCoordinatorView,
//            coordinator: appCoordinator,
//            window: window
//        )
//        window.rootViewController = rootViewController
//        appCoordinator.start(with: appCoordinatorOptions)
//        self.appCoordinator = appCoordinator
//        self.window = window
//        appOverlaysManager.setMainWindow(window)
//        window.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
//        window.makeKeyAndVisible()
//    }
//
//    private func hideLockView() {
//        lockWindow?.isHidden = true
//        lockWindow = nil
//    }
//
//    // MARK: - Incoming actions
//
//    /// Hot handle deeplinks `https://tangem.com, https://app.tangem.com`
//    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
//        handleActivities([userActivity])
//    }
//
//    /// Hot handle universal links  with `tangem://` scheme
//    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        handleUrlContexts(URLContexts)
//    }
//
//    [REDACTED_USERNAME]
//    private func handleActivities(_ userActivities: Set<NSUserActivity>) -> Bool {
//        for activity in userActivities {
//            switch activity.activityType {
//            case NSUserActivityTypeBrowsingWeb:
//                if let url = activity.webpageURL {
//                    if incomingActionHandler.handleIncomingURL(url) {
//                        return true
//                    }
//                }
//
//            default:
//                if incomingActionHandler.handleIntent(activity.activityType) {
//                    return true
//                }
//            }
//        }
//
//        return false
//    }
//
//    [REDACTED_USERNAME]
//    private func handleUrlContexts(_ urlContexts: Set<UIOpenURLContext>) -> Bool {
//        for context in urlContexts {
//            if incomingActionHandler.handleIncomingURL(context.url) {
//                return true
//            }
//        }
//
//        return false
//    }
// }
