//
//  SafariManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SafariServices

// MARK: - SafariManager

protocol SafariManager {
    /// You should retain the handle in the coordionator always
    func openURL(_ url: URL, configuration: SafariConfiguration, onDismiss: @escaping (URL) -> Void) -> SafariHandle

    /// For any calls without callback
    func openURL(_ url: URL, configuration: SafariConfiguration)
}

extension SafariManager {
    func openURL(_ url: URL, configuration: SafariConfiguration = .init(), onDismiss: @escaping (URL) -> Void = { _ in }) -> SafariHandle {
        openURL(url, configuration: configuration, onDismiss: onDismiss)
    }

    func openURL(_ url: URL, configuration: SafariConfiguration = .init()) {
        openURL(url, configuration: configuration)
    }
}

// MARK: - SafariHandle

protocol SafariHandle: AnyObject {}

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

class CommonSafariManager: SafariManager {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private weak var context: SafariContext?

    init() {
        incomingActionManager.becomeFirstResponder(self)
    }

    func openURL(_ url: URL, configuration: SafariConfiguration) {
        openURL(url, configuration: configuration) { _ in }
    }

    @discardableResult
    func openURL(
        _ url: URL,
        configuration: SafariConfiguration,
        onDismiss: @escaping (URL) -> Void
    ) -> SafariHandle {
        AppLog.shared.debug("Open URL: \(url)")
        let controller = SFSafariViewController(url: url)
        controller.modalPresentationStyle = .pageSheet
        controller.dismissButtonStyle = configuration.dismissButtonStyle.sfDismissButtonStyle
        let context = SafariContext(controller: controller, onDismiss: onDismiss)
        self.context = context
        AppPresenter.shared.show(controller)
        return context
    }

    func dismiss(with url: URL) {
        // already dismissed by user, but we received an url from Safari
        if context?.controller.presentingViewController == nil {
            context?.onDismiss(url)
            return
        }

        context?.controller.dismiss(animated: true, completion: { [weak self] in
            self?.context?.onDismiss(url)
        })
    }
}

// MARK: - IncomingActionResponder

extension CommonSafariManager: IncomingActionResponder {
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
    let controller: SFSafariViewController
    let onDismiss: (URL) -> Void

    init(controller: SFSafariViewController, onDismiss: @escaping ((URL) -> Void)) {
        self.controller = controller
        self.onDismiss = onDismiss
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
