//
//  MailView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {

    var dataCollector: EmailDataCollector
    
    @Environment(\.presentationMode) var presentation
    let emailType: EmailType

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var presentation: PresentationMode
        
        let emailType: EmailType

        init(presentation: Binding<PresentationMode>, emailType: EmailType) {
            _presentation = presentation
            self.emailType = emailType
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            guard result == .sent || result == .failed else {
                $presentation.wrappedValue.dismiss()
                return
            }
            let title = error == nil ? emailType.sentEmailAlertTitle : emailType.failedToSendAlertTitle
            let message = error == nil ? emailType.sentEmailAlertMessage : emailType.failedToSendAlertMessage(error)
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "common_ok".localized, style: .default, handler: { [weak self] _ in
                if error == nil {
                    self?.$presentation.wrappedValue.dismiss()
                }
            })
            alert.view.tintColor = .tangemTapGrayDark6
            alert.setValue(NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.tangemTapGrayDark6, .font: UIFont.systemFont(ofSize: 16, weight: .bold)]), forKey: "attributedTitle")
            alert.setValue(NSAttributedString(string: message, attributes: [.foregroundColor: UIColor.tangemTapGrayDark6, .font: UIFont.systemFont(ofSize: 14, weight: .regular)]), forKey: "attributedMessage")
            alert.addAction(okAction)
            controller.present(alert, animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, emailType: emailType)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["andoran90@gmail.com"])
        vc.setSubject(emailType.emailSubject)
        var messageBody = "\n" + emailType.emailPreface
        messageBody.append("\n\n\n")
        messageBody.append(emailType.dataCollectionMessage + "\n")
        messageBody.append(dataCollector.dataForEmail)
        vc.setMessageBody(messageBody, isHTML: false)
        if let attachment = dataCollector.attachment {
            vc.addAttachmentData(attachment, mimeType: "text/plain", fileName: "logs.txt")
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {

    }
}
