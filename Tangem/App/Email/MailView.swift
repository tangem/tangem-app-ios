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
        messageBody.append("\n\n")
        vc.setMessageBody(messageBody, isHTML: false)

        let logFiles = viewModel.logsComposer.getLogFiles()
        logFiles.forEach { originalURL in
            let zipName = (originalURL.lastPathComponent as NSString).deletingPathExtension + ".zip"
            try? zip(itemAtURL: originalURL, in: FileManager().temporaryDirectory, zipName: zipName, completion: { result in
                if case .success(let zipURL) = result {
                    let data = (try? Data(contentsOf: zipURL)) ?? Data()
                    vc.addAttachmentData(data, mimeType: "application/x-deflate", fileName: zipName)
                }
            })
        }
//
//        let fileManager = FileManager.default
//        viewModel.logsComposer.getLogsData().forEach { data in
//            let archiveName = (data.key as NSString).deletingPathExtension + ".gz"
//            let archiveURL = fileManager.temporaryDirectory.appendingPathComponent(archiveName, conformingTo: .gzip)
//            let archive = ZlibArchive.archive(data: data.value)
//            vc.addAttachmentData(archive, mimeType: "application/gzip", fileName: archiveName)
//        }

//        let fileManager = FileManager()
//        logFiles.forEach { originalURL in
//            let fileName = (originalURL.lastPathComponent as NSString).deletingPathExtension + ".zip"
//            let archiveURL = fileManager.temporaryDirectory.appendingPathComponent(fileName, conformingTo: .zip)
//            try? fileManager.zipItem(at: originalURL, to: archiveURL, compressionMethod: .deflate)
//            vc.addAttachmentData((try? Data(contentsOf: archiveURL)) ?? Data(), mimeType: "application/zip", fileName: fileName)
//        }

//        viewModel.logsComposer.getLogsData().forEach {
//            if let compressed = try? $0.value.compressed(using: .zlib) {
//                vc.addAttachmentData(compressed, mimeType: "application/x-deflate", fileName: ($0.key as NSString).deletingPathExtension + ".zip")
//            } else {
//                vc.addAttachmentData($0.value, mimeType: "text/plain", fileName: $0.key)
//            }
//        }

        return vc
    }

    /// Zip the itemAtURL (file or folder) into the destinationFolderURL with the given zipName
    /// - Parameters:
    ///   - itemURL: File or folder to zip
    ///   - destinationFolderURL: destination folder
    ///   - zipName: zip file name
    /// - Throws: Error in case of failure in generating or moving the zip
    func zip(itemAtURL itemURL: URL, in destinationFolderURL: URL, zipName: String, completion: @escaping (Result<URL, Error>) -> Void) throws {
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: itemURL, options: [.forUploading], error: &error) { zipUrl in
            // zipUrl points to the zip file created by [REDACTED_AUTHOR]
            // zipUrl is valid only until the end of this block, so we move the file to a temporary folder
            let finalUrl = destinationFolderURL.appendingPathComponent(zipName)
            do {
                try? FileManager.default.removeItem(at: finalUrl)
                try FileManager.default.moveItem(at: zipUrl, to: finalUrl)
                completion(.success(finalUrl))
            } catch let localError {
                completion(.failure(localError))
            }
        }

        if let error {
            throw error
        }
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: UIViewControllerRepresentableContext<MailView>
    ) {}
}

private struct MailViewPlaceholder: View {
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
