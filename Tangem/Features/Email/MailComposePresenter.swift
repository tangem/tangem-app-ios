//
//  MailComposePresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import MessageUI
import SwiftUI
import TangemLocalization

@MainActor
final class MailComposePresenter: NSObject {
    private var emailInProcess: EmailType?
    private var completionInProcess: (() -> Void)?

    override fileprivate nonisolated init() {}

    func present(viewModel: MailViewModel, completion: (() -> Void)? = nil) {
        let viewController: UIViewController

        if MFMailComposeViewController.canSendMail() {
            viewController = makeMailViewController(using: viewModel)
            emailInProcess = viewModel.emailType
            completionInProcess = completion
        } else {
            viewController = UIHostingController(rootView: NoMailAccountPlaceholderView())
            emailInProcess = nil
            completionInProcess = nil
        }

        let presentingViewController: UIViewController?

        // [REDACTED_USERNAME]: topViewController may be in the process of being dismissed
        // (for example, when presenting from a SwiftUI .sheet that is currently closing).
        // In that case, we must fall back to another valid presenter.

        if let topViewController = UIApplication.mainWindow?.topViewController, !topViewController.isBeingDismissed {
            presentingViewController = topViewController
        } else {
            presentingViewController = UIApplication.mainWindow?.rootViewController
        }

        presentingViewController?.present(viewController, animated: true)
    }
}

// MARK: - Factory methods

extension MailComposePresenter {
    private func makeMailViewController(using viewModel: MailViewModel) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = self

        viewController.setToRecipients([viewModel.recipient])
        viewController.setSubject(viewModel.emailType.emailSubject)

        var messageBody = ""
        if let preface = viewModel.emailType.emailPreface {
            messageBody.append("\n")
            messageBody.append(preface)
            messageBody.append("\n\n")
        }

        if let log = viewModel.logsComposer.getInfoData(), let messageLog = String(data: log, encoding: .utf8) {
            messageBody.append(messageLog)
        }

        viewController.setMessageBody(messageBody, isHTML: false)

        if FeatureProvider.isAvailable(.logs), let (data, file) = viewModel.logsComposer.getZipLogsData() {
            viewController.addAttachmentData(data, mimeType: "application/zip", fileName: file.lastPathComponent)
        }

        return viewController
    }

    private static func makeAlertController(
        for emailType: EmailType,
        error: (any Error)?,
        dismissAction: @escaping () -> Void
    ) -> UIAlertController {
        let title: String
        let message: String

        if let error {
            title = emailType.failedToSendAlertTitle
            message = emailType.failedToSendAlertMessage(error)
        } else {
            title = emailType.sentEmailAlertTitle
            message = emailType.sentEmailAlertMessage
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: Localization.commonOk, style: .default) { _ in
            dismissAction()
        }
        alertController.addAction(okAction)

        return alertController
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension MailComposePresenter: @preconcurrency MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        defer {
            emailInProcess = nil
            completionInProcess?()
            completionInProcess = nil
        }

        let dismissAction = { [controller] in
            controller.dismiss(animated: true)
        }

        switch result {
        case .sent, .failed:
            break

        case .cancelled, .saved:
            dismissAction()
            return

        @unknown default:
            assertionFailure("Unhandled MFMailComposeResult case: \(result)")
            dismissAction()
            return
        }

        guard let emailInProcess else {
            dismissAction()
            return
        }

        let alertController = Self.makeAlertController(for: emailInProcess, error: error, dismissAction: dismissAction)
        controller.present(alertController, animated: true)
    }
}

// MARK: - InjectionValues property

extension InjectedValues {
    private enum MailComposePresenterInjectionKey: InjectionKey {
        static var currentValue = MailComposePresenter()
    }

    private var _mailComposePresenter: MailComposePresenter {
        get { Self[MailComposePresenterInjectionKey.self] }
        set { Self[MailComposePresenterInjectionKey.self] = newValue }
    }

    var mailComposePresenter: MailComposePresenter {
        _mailComposePresenter
    }
}
