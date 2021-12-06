//
//  BottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct AddressQrBottomSheetContent: View {
    
    var shareAddress: String
    var address: String
    var qrNotice: String

    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: QrCodeGenerator.generateQRCode(from: shareAddress))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(width: 206, height: 206))
                .padding(.top, 49)
                .padding(.bottom, 30)
            Text(qrNotice)
                .frame(maxWidth: 225)
                .font(.system(size: 18, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemGrayDark)
            HStack(spacing: 10) {
                Button(action: {
                        showCheckmark = true
                    UIPasteboard.general.string = address
                    
                    let notificationGenerator = UINotificationFeedbackGenerator()
                    notificationGenerator.notificationOccurred(.success)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            showCheckmark = false
                    }
                    
                }, label: {
                    HStack{
                        Text(address)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 100)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.tangemGrayDark6)
                        
                        Group {
                        showCheckmark ?
                            Image(systemName: "checkmark")
                            .id("1")
                            : Image(systemName: "doc.on.clipboard")
                            .id("2")
                        }
                        .frame(width: 18, height: 18)
                        .foregroundColor(.tangemGreen)
                    }
                    .frame(height: 40)
                    .padding(.horizontal, 16)
                    .background(Color.tangemBgGray)
                    .cornerRadius(20)
                })
                Button(action: { showShareSheet() }, label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .frame(height: 40)
                        .foregroundColor(.tangemGreen)
                        .padding(.horizontal, 16)
                        .background(Color.tangemBgGray)
                        .cornerRadius(20)
                })
            }
            .padding(.top, 30)
            .padding(.bottom, 50)
        }
        
    }
    
    private func showShareSheet() {
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.topViewController?.present(av, animated: true, completion: nil)
    }
    
}


struct AddressQrBottomSheetPreviewView: View {
    
    @ObservedObject var model: BottomSheetPreviewProvider
    
    var body: some View {
        ZStack {
            Button(action: {
                model.isBottomSheetPresented.toggle()
            }, label: {
                Text("Show bottom sheet")
                    .padding()
            })
            BottomSheetView(
                isPresented: model.$isBottomSheetPresented,
                hideBottomSheetCallback: {
                    model.isBottomSheetPresented = false
                }, content: {
                    AddressQrBottomSheetContent(shareAddress: "eth:0x01232483902f903678a098bce",
                                                address: "0x01232483902f903678a098bce",
                                                qrNotice: "BTC")
                })
        }
        
    }
}

struct AddressQrBottomSheet_Previews: PreviewProvider {
    
    static var previews: some View {
        AddressQrBottomSheetPreviewView(model: BottomSheetPreviewProvider())
            .previewGroup(devices: [.iPhoneX], withZoomed: false)
        
        AddressQrBottomSheetContent(shareAddress: "eth:0x01232483902f903678a098bce",
                                    address: "0x01232483902f903678a098bce",
                                    qrNotice: "BTC")
    }
    
}

