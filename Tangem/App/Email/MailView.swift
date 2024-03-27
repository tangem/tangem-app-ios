//
//  MailView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import MessageUI
import Compression
import AppleArchive
import System
import Foundation
import ZIPFoundation

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
        let fileManager = FileManager()
//        logFiles.forEach { originalURL in
//            let zipName = (originalURL.lastPathComponent as NSString).deletingPathExtension + ".zip"
//            let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(zipName, conformingTo: .zip)
//            do {
//                try? fileManager.removeItem(at: destinationURL)
//                try fileManager.zipItem(at: originalURL, to: destinationURL, compressionMethod: .deflate)
//                let data = (try? Data(contentsOf: destinationURL)) ?? Data()
//                vc.addAttachmentData(data, mimeType: "application/zip", fileName: zipName)
//            } catch {
//                print("Creation of ZIP archive failed with error:\(error)")
//            }
//        }

        logFiles.forEach { originalURL in
            guard let path = FilePath(originalURL),
                  let readFileStream = ArchiveByteStream.fileStream(
                      path: path,
                      mode: .readOnly,
                      options: [],
                      permissions: FilePermissions(rawValue: 0o644)
                  ) else {
                return
            }
            defer {
                try? readFileStream.close()
            }

            let destinationFileName = originalURL.lastPathComponent + ".lzfse"

            let destinationFilePath = NSTemporaryDirectory() + destinationFileName

            try? fileManager.removeItem(atPath: destinationFilePath)

            guard let writeFileStream = ArchiveByteStream.fileStream(
                path: FilePath(destinationFilePath),
                mode: .writeOnly,
                options: [.create],
                permissions: FilePermissions(rawValue: 0o644)
            ) else {
                return
            }
            defer {
                try? writeFileStream.close()
            }

            guard let compressStream = ArchiveByteStream.compressionStream(
                using: .zlib,
                writingTo: writeFileStream
            ) else {
                return
            }
            defer {
                try? compressStream.close()
            }

            do {
                let archives = try ArchiveByteStream.process(
                    readingFrom: readFileStream,
                    writingTo: compressStream
                )
                print(archives)
            } catch {
                print("Handle `ArchiveByteStream.process` failed. with error: \(error)")
            }

            let archiveURL = URL(fileURLWithPath: destinationFilePath, isDirectory: false)
            vc.addAttachmentData((try? Data(contentsOf: archiveURL)) ?? Data(), mimeType: "application/appleArchive", fileName: destinationFileName)
        }

//        viewModel.logsComposer.getLogsData().forEach { data in
//            let archiveName = (data.key as NSString).deletingPathExtension + ".aar"
//            let archiveURL = fileManager.temporaryDirectory.appendingPathComponent(archiveName, conformingTo: .appleArchive)
//            if let archive = try? data.value.compressed(using: .zlib) {
//                vc.addAttachmentData(archive, mimeType: "application/appleArchive", fileName: archiveName)
//            } else {
//                vc.addAttachmentData(data.value, mimeType: "text/plain", fileName: data.key)
//            }
//        }

        return vc
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
