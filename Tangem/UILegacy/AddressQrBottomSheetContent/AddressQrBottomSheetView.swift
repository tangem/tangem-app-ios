//
//  AddressQrBottomSheetContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemUI

struct AddressQrBottomSheetContentViewModel: Identifiable {
    let id: UUID = .init()
    var shareAddress: String
    var address: String
    var qrNotice: String

    func logCopyAddress() {
        Analytics.log(.buttonCopyAddress, analyticsSystems: .all)
    }

    func logShareAddress() {
        Analytics.log(.buttonShareAddress)
    }
}

struct AddressQrBottomSheetContent: View {
    let viewModel: AddressQrBottomSheetContentViewModel

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: QrCodeGenerator.generateQRCode(from: viewModel.shareAddress))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(width: 206, height: 206))
                .padding(.top, 49)
                .padding(.bottom, 30)
            Text(viewModel.qrNotice)
                .frame(maxWidth: 225)
                .font(.system(size: 18, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(Colors.Old.tangemGrayDark)
            HStack(spacing: 10) {
                Button(action: {
                    showCheckmark = true
                    viewModel.logCopyAddress()
                    UIPasteboard.general.string = viewModel.address

                    let notificationGenerator = UINotificationFeedbackGenerator()
                    notificationGenerator.notificationOccurred(.success)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showCheckmark = false
                    }

                }, label: {
                    HStack {
                        Text(viewModel.address)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 100)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Colors.Icon.primary1)

                        Group {
                            showCheckmark ?
                                Image(systemName: "checkmark")
                                .id("1")
                                : Image(systemName: "doc.on.clipboard")
                                .id("2")
                        }
                        .frame(width: 18, height: 18)
                        .foregroundColor(Colors.Icon.accent)
                    }
                    .frame(height: 40)
                    .padding(.horizontal, 16)
                    .background(Colors.Old.tangemBgGray)
                    .cornerRadius(20)
                })
                Button(action: { showShareSheet() }, label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .frame(height: 40)
                        .foregroundColor(Colors.Icon.accent)
                        .padding(.horizontal, 16)
                        .background(Colors.Old.tangemBgGray)
                        .cornerRadius(20)
                })
            }
            .padding(.top, 30)
            .padding(.bottom, 50)
        }
    }

    private func showShareSheet() {
        viewModel.logShareAddress()
        let av = UIActivityViewController(activityItems: [viewModel.address], applicationActivities: nil)
        UIApplication.topViewController?.present(av, animated: true, completion: nil)
    }
}

@available(iOS 17.0, *)
#Preview("Sheet") {
    final class AddressQrBottomSheetPreviewTrigger: Identifiable {}

    @Previewable @State var isBottomSheetPresented: AddressQrBottomSheetPreviewTrigger?

    return ZStack {
        Button(action: {
            isBottomSheetPresented = (isBottomSheetPresented == nil) ? AddressQrBottomSheetPreviewTrigger() : nil
        }, label: {
            Text("Show bottom sheet")
                .padding()
        })
        NavHolder()
            .bottomSheet(item: $isBottomSheetPresented, backgroundColor: Colors.Background.tertiary) { _ in
                AddressQrBottomSheetContent(
                    viewModel: .init(
                        shareAddress: "eth:0x01232483902f903678a098bce",
                        address: "0x01232483902f903678a098bce",
                        qrNotice: "BTC"
                    )
                )
            }
    }
    .previewGroup(devices: [.iPhoneX], withZoomed: false)
}

#Preview("Content") {
    AddressQrBottomSheetContent(
        viewModel: .init(
            shareAddress: "eth:0x01232483902f903678a098bce",
            address: "0x01232483902f903678a098bce",
            qrNotice: "BTC"
        )
    )
}
