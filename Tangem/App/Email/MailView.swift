//
//  MailView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    let viewModel: MailViewModel

    @Environment(\.presentationMode) private var presentation

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode

        let emailType: EmailType

        init(presentation: Binding<PresentationMode>, emailType: EmailType) {
            _presentation = presentation
            self.emailType = emailType
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            guard result == .sent || result == .failed else {
                $presentation.wrappedValue.dismiss()
                return
            }
            let title = error == nil ? emailType.sentEmailAlertTitle : emailType.failedToSendAlertTitle
            let message = error == nil ? emailType.sentEmailAlertMessage : emailType.failedToSendAlertMessage(error)
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: Localization.commonOk, style: .default, handler: { [weak self] _ in
                if error == nil {
                    self?.$presentation.wrappedValue.dismiss()
                }
            })
            alert.view.tintColor = .tangemGrayDark6
            alert.setValue(NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.tangemGrayDark6, .font: UIFont.systemFont(ofSize: 16, weight: .bold)]), forKey: "attributedTitle")
            alert.setValue(NSAttributedString(string: message, attributes: [.foregroundColor: UIColor.tangemGrayDark6, .font: UIFont.systemFont(ofSize: 14, weight: .regular)]), forKey: "attributedMessage")
            alert.addAction(okAction)
            controller.present(alert, animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, emailType: viewModel.emailType)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> UIViewController {
        guard MFMailComposeViewController.canSendMail() else {
            return UIHostingController(rootView: MailViewPlaceholder(presentationMode: presentation))
        }

        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([viewModel.recipient])
        vc.setSubject(viewModel.emailType.emailSubject)
        var messageBody = "\n" + viewModel.emailType.emailPreface
        messageBody.append("\n\n\n")
        messageBody.append(viewModel.emailType.dataCollectionMessage + "\n")
        messageBody.append(viewModel.dataCollector.dataForEmail)
        vc.setMessageBody(messageBody, isHTML: false)
        if let attachment = viewModel.dataCollector.attachment {
            vc.addAttachmentData(attachment, mimeType: "text/plain", fileName: "logs.txt")
        }
        return vc
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: UIViewControllerRepresentableContext<MailView>
    ) {}
}

fileprivate struct MailViewPlaceholder: View {
    @Binding var presentationMode: PresentationMode

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(Localization.commonClose) {
                    presentationMode.dismiss()
                }
                Spacer()
            }
            .padding([.horizontal, .top])
            Spacer()
            Text(Localization.mailErrorNoAccountsTitle)
                .font(.title)
            Text(Localization.mailErrorNoAccountsBody)
                .font(.body)
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

struct MailViewPlaceholder_Previews: PreviewProvider {
    @Environment(\.presentationMode) static var presentation

    static var previews: some View {
        MailViewPlaceholder(presentationMode: .constant(presentation.wrappedValue))
    }
}
