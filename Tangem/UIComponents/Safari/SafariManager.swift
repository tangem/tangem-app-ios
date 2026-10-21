//
//  SafariManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SafariServices
import TangemFoundation

// MARK: - SafariManager

protocol SafariManager {
    /// You should retain the handle in the coordinator always
    func openURL(
        _ url: URL,
        configuration: SafariConfiguration,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL) -> Void
    ) -> SafariHandle?

    /// For any calls without callback
    func openURL(_ url: URL, configuration: SafariConfiguration)
}

extension SafariManager {
    func openURL(_ url: URL, configuration: SafariConfiguration = .init(), onSuccess: @escaping (URL) -> Void = { _ in }) -> SafariHandle? {
        openURL(url, configuration: configuration, onDismiss: {}, onSuccess: onSuccess)
    }

    func openURL(_ url: URL, configuration: SafariConfiguration = .init()) {
        openURL(url, configuration: configuration)
    }
}

// MARK: - SafariHandle

protocol SafariHandle: AnyObject {
    func isMatching(startingURL: URL) -> Bool
}

// MARK: - Dependencies

private struct SafariManagerKey: InjectionKey {
    static var currentValue: SafariManager = CommonSafariManager()
}

extension InjectedValues {
    var safariManager: SafariManager {
        get { Self[SafariManagerKey.self] }
        set { Self[SafariManagerKey.self] = newValue }
    }
}

// MARK: - CommonSafariManager

class CommonSafariManager: NSObject, SafariManager {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private weak var context: SafariContext?

    func openURL(_ url: URL, configuration: SafariConfiguration) {
        openURL(url, configuration: configuration, onDismiss: {}, onSuccess: { _ in })
    }

    @discardableResult
    func openURL(
        _ url: URL,
        configuration: SafariConfiguration,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL) -> Void
    ) -> SafariHandle? {
        guard url.isWebURL else {
            AppLogger.warning("Can't open a non-web URL in Safari: \(url)")
            onDismiss()
            return nil
        }

        AppLogger.info("Open URL: \(url)")
        let controller = SFSafariViewController(url: url)
        controller.modalPresentationStyle = .pageSheet
        controller.dismissButtonStyle = configuration.dismissButtonStyle.sfDismissButtonStyle
        controller.delegate = self
        controller.presentationController?.delegate = self

        // The listener lives as long as a flow is waiting for its redirect — which outlasts the browser itself,
        // because a redirect can land after the user has closed it, and the flow that opened it still has to
        // hear about it. What ends the wait is the redirect arriving, or the wallet session going away.
        incomingActionManager.becomeFirstResponder(self)

        let context = SafariContext(initialURL: url, controller: controller, onDismiss: onDismiss, onSuccess: onSuccess)
        self.context = context
        AppPresenter.shared.show(controller)
        return context
    }

    func dismiss(with url: URL) {
        stopListeningForRedirects()

        // already dismissed by user, but we received an url from Safari
        if context?.controller.presentingViewController == nil {
            context?.onSuccess(url)
            return
        }

        context?.controller.dismiss(animated: true, completion: { [weak self] in
            self?.context?.onSuccess(url)
        })
    }
}

// MARK: - SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate

extension CommonSafariManager: SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        context?.onDismiss()
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        context?.onDismiss()
    }
}

// MARK: - IncomingActionResponder

extension CommonSafariManager: IncomingActionResponder {
    fileprivate func stopListeningForRedirects() {
        incomingActionManager.resignFirstResponder(self)
    }

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .dismissSafari(let url) = action else {
            return false
        }

        dismiss(with: url)
        return true
    }
}

// MARK: - SafariContext

class SafariContext: SafariHandle {
    let initialURL: URL
    let controller: SFSafariViewController
    let onDismiss: () -> Void
    let onSuccess: (URL) -> Void

    init(
        initialURL: URL,
        controller: SFSafariViewController,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL) -> Void
    ) {
        self.initialURL = initialURL
        self.controller = controller
        self.onDismiss = onDismiss
        self.onSuccess = onSuccess
    }

    func isMatching(startingURL: URL) -> Bool {
        initialURL == startingURL
    }
}

// MARK: - Configuration mappings

private extension SafariConfiguration.DismissButtonStyle {
    var sfDismissButtonStyle: SFSafariViewController.DismissButtonStyle {
        switch self {
        case .done:
            return .done
        case .close:
            return .close
        case .cancel:
            return .cancel
        }
    }
}
