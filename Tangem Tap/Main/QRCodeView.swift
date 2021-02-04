//
//  QRCodeView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import EFQRCode
import UIKit

struct QRCodeView: View {
    let title: String
    let shareString: String
    @State var userBrightness: CGFloat = 0.5
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    private static let initialOffsetHeight: CGFloat = UIScreen.main.bounds.height
    
    @State private var offset = CGSize(width: 0, height: initialOffsetHeight)
    @State private var opacity = 0.0
    
    var body: some View {
        
        let dragGesture = DragGesture()
            .onChanged { value in
                offset.height = max(0, value.translation.height)
                opacity = Double(1.0 - offset.height/QRCodeView.initialOffsetHeight)
            }
            .onEnded { value in
                
                let shouldDismiss = value.predictedEndTranslation.height >= value.translation.height
                let finalOffsetHeight = shouldDismiss ? QRCodeView.initialOffsetHeight : 0
                let finalOpacity = shouldDismiss ? 0.0 : 1.0
                
                withAnimation(Animation.linear(duration: 0.1)) {
                    offset.height = finalOffsetHeight
                    opacity = finalOpacity
                }
                
                if shouldDismiss {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.viewControllerHolder?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        
        VStack {
            Spacer()
            
            VStack {
                VStack(alignment: .center, spacing: 24.0) {
                    HStack {
                        Text(title)
                            .font(Font.system(size: 30.0, weight: .bold, design: .default) )
                            .foregroundColor(Color.tangemTapGrayDark6)
                        Spacer()
                    }
                    Image(uiImage: self.getQrCodeImage(width: 600.0, height: 600.0))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Text(shareString)
                        .font(Font.system(size: 13.0, weight: .regular, design: .default) )
                        .foregroundColor(Color.tangemTapGrayDark)
                        .multilineTextAlignment(.center)
                }
                .padding(.all, 36.0)
            }
            .background(Color.white)
            .cornerRadius(14)
            .offset(offset)
            .opacity(opacity)
            .gesture(dragGesture)
            
            Spacer()
        }
        .padding(.horizontal, 12.0)
        .background(Color.clear)
        .onAppear {
            self.userBrightness = UIScreen.main.brightness
            UIScreen.main.animateBrightness(from: UIScreen.main.brightness, to: 1.0)
            withAnimation(Animation.easeInOut(duration: 0.2))  {
                offset = CGSize.zero
                opacity = 1
            }
        }
        .onWillDisappear {
            UIScreen.main.animateBrightness(from: UIScreen.main.brightness, to: self.userBrightness)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            UIScreen.main.animateBrightness(from: UIScreen.main.brightness, to: self.userBrightness)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            self.userBrightness = UIScreen.main.brightness
            UIScreen.main.animateBrightness(from: UIScreen.main.brightness, to: 1.0)
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.clear)
       
    }
    
    
    private func getQrCodeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let padding: CGFloat = 10
        
        if let cgImage = EFQRCode.generate(content: shareString,
                                           size: EFIntSize(width: Int(width), height: Int(height)), backgroundColor: CGColor(red: 0, green: 0, blue: 0, alpha: 0)) {
            return UIImage(cgImage: cgImage.cropping(to: CGRect(x: padding,
                                                                y: padding,
                                                                width: width - padding,
                                                                height: height-padding))!,
                           scale: 1.0,
                           orientation: .up)
        } else {
            return UIImage.imageWithSize(width: width, height: height, filledWithColor: UIColor.tangemTapBgGray )
        }
    }
}


struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(title: "Bitcoin Wallet",
                   shareString: "asdjfhaskjfwjb5khjv3kv3lb535345435cdgdcgdgjshdgjkewk345t3")
            .background(Color.gray)
    }
}
