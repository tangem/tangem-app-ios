//
//  RoundedRectButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct RoundedRectButton: View {
    var action: () -> Void = { }
    var backgroundColor: Color = .init(red: 224.0/255.0, green: 230.0/255.0, blue: 250.0/255.0, opacity: 1)
    var systemImageName: String?
    let title: String
    var foregroundColor: Color = .tangemBlue
    var withVerification: Bool = false
    var isDisabled = false
    
    @State private var isVerify = false
    
    var body: some View {
        Button(action: {
            action()
            if withVerification {
                playVerifyAnimation()
            }
        }, label: {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                if let imageName = systemImageName {
                    Image(systemName: isVerify ? "checkmark" : imageName )
                }
                Text(title)
            }
            .padding(.horizontal, 8)
            .frame(minWidth: 62,
                   idealWidth: 84,
                   maxWidth: 84,
                   minHeight: 28,
                   idealHeight: 28,
                   maxHeight: 28)
            .font(Font.system(size: 13.0, weight: .medium, design: .default))
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(!isDisabled ? Color.clear : Color.white.opacity(0.4))
        })
    }
    
    private func playVerifyAnimation() {
        withAnimation {
            isVerify = true
        }
        
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                isVerify = false
            }
        }
    }
}

struct RoundedRectButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            RoundedRectButton (systemImageName: "doc.on.clipboard", title: "Copy", withVerification: true)
        RoundedRectButton (systemImageName: "square.and.arrow.up", title: "Share")
        }
    }
}
