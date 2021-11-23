//
//  OnboardingMessagesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingMessagesView: View {
    
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let onTitleTapCallback: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .frame(maxWidth: .infinity)
//                .background(Color.red)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(.tangemGrayDark6)
                .padding(.bottom, 14)
                .onTapGesture {
                    // [REDACTED_TODO_COMMENT]
                    //onTitleTapCallback?()
                }
                .transition(.opacity)
                .id("onboarding_title_\(title)")
            Text(subtitle)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
//                .background(Color.yellow)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.tangemGrayDark6)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
                .id("onboarding_subtitle_\(subtitle)")
        }
    }
    
}

struct OnboardingMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            OnboardingMessagesView(title: "Create wallet",
                                   subtitle: "Tap card to create wallet") {
                
            }.background(Color.red)
            
            OnboardingMessagesView(title: "Create wallet",
                                   subtitle: "All the backup cards can be used as full-functoinal wallets with the identical keys.") {
            }.background(Color.green)
        }
        .padding(.horizontal, 80)
    }
}
