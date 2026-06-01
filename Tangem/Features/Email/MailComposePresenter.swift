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
        guard MFMailComposeViewController.canSendMail() else {
            emailInProcess = nil
            completionInProcess = nil
            presentMailFallbackActionSheet(viewModel: viewModel)
            return
        }

        emailInProcess = viewModel.emailType
        completionInProcess = completion

        viewModel.logsComposer.getLogsArchive { [weak self] logsArchive in
            Task { @MainActor in
                guard let self else { return }
                let viewController = self.makeMailViewController(using: viewModel, logsArchive: logsArchive)
                self.present(viewController: viewController)
            }
        }
    }
}

// MARK: - Presentation

extension MailComposePresenter {
    private func present(viewController: UIViewController) {
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

    private func presentMailFallbackActionSheet(viewModel: MailViewModel) {
        Analytics.log(.emailNoMailSheetOpened, analyticsSystems: .all)

        let fallbackView = MailFallbackView(
            openMailAction: { [weak self] in self?.openMail(viewModel: viewModel) },
            shareLogsAction: { [weak self] in self?.shareLogs(viewModel: viewModel) }
        )

        let hostingController = UIHostingController(rootView: fallbackView)
        hostingController.sheetPresentationController?.detents = [.custom { _ in MailFallbackView.preferredHeight }]
        hostingController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController: hostingController)
    }

    private func openMail(viewModel: MailViewModel) {
        Analytics.log(.emailOpenMail, analyticsSystems: .all)

        var components = URLComponents(string: "mailto:\(viewModel.recipient)")
        components?.queryItems = [URLQueryItem(name: "subject", value: viewModel.emailType.emailSubject)]
        if let preface = viewModel.emailType.emailPreface {
            components?.queryItems?.append(URLQueryItem(name: "body", value: preface))
        }
        if let url = components?.url {
            UIApplication.shared.open(url)
        }
    }

    private func shareLogs(viewModel: MailViewModel) {
        Analytics.log(.emailShareLogs, analyticsSystems: .all)

        viewModel.logsComposer.getLogsArchive { logsArchive in
            Task { @MainActor in
                guard let archiveURL = logsArchive?.file else { return }
                let activityVC = UIActivityViewController(activityItems: [archiveURL], applicationActivities: nil)
                self.present(viewController: activityVC)
            }
        }
    }
}

// MARK: - Factory methods

extension MailComposePresenter {
    private func makeMailViewController(
        using viewModel: MailViewModel,
        logsArchive: (data: Data, file: URL)?
    ) -> MFMailComposeViewController {
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

        viewController.setMessageBody(messageBody, isHTML: false)

        if let logsArchive {
            viewController.addAttachmentData(
                logsArchive.data,
                mimeType: "application/zip",
                fileName: logsArchive.file.lastPathComponent
            )
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
