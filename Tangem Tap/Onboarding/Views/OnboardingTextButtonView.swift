//
//  OnboardingTextButtonView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ButtonsSettings {
    let mainTitle: LocalizedStringKey
    let mainSize: ButtonSize
    let mainAction: (() -> Void)?
    let mainIsBusy: Bool
    
    let supplementTitle: LocalizedStringKey
    let supplementSize: ButtonSize
    let supplementAction: (() -> Void)?
    let isVisible: Bool
    let containSupplementButton: Bool
}

struct OnboardingTextButtonView: View {
    
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var textOffset: CGSize = .zero
    let buttonsSettings: ButtonsSettings
    
    let titleAction: (() -> Void)?
    
    @ViewBuilder
    var buttons: some View {
        VStack(spacing: 10) {
            TangemButton(isLoading: buttonsSettings.mainIsBusy,
                         title: buttonsSettings.mainTitle,
                         size: buttonsSettings.mainSize) {
                withAnimation {
                    buttonsSettings.mainAction?()
                }
            }
            .buttonStyle(TangemButtonStyle(color: .green,
                                           font: .system(size: 17, weight: .semibold),
                                           isDisabled: false))
            
            if buttonsSettings.containSupplementButton {
                TangemButton(isLoading: false,
                             title: buttonsSettings.supplementTitle,
                             size: buttonsSettings.supplementSize) {
                    buttonsSettings.supplementAction?()
                }
                .opacity(buttonsSettings.isVisible ? 1.0 : 0.0)
                .allowsHitTesting(buttonsSettings.isVisible)
                .buttonStyle(TangemButtonStyle(color: .transparentWhite,
                                               font: .system(size: 17, weight: .semibold),
                                               isDisabled: false))
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingMessagesView(title: title,
                                   subtitle: subtitle) {
                titleAction?()
            }
            .frame(alignment: .top)
            .offset(textOffset)
            Spacer()
            buttons
                .padding(.bottom, buttonsSettings.containSupplementButton ? 16 : 20)
                
        }
        .frame(maxHeight: 304)
    }
    
}

struct OnboardingTextButtonView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingTextButtonView(
            title: "Create a wallet",
            subtitle: "Let’s generate all the keys on your card and create a secure wallet",
            textOffset: .init(width: 0, height: -100),
            buttonsSettings: .init(
                mainTitle: "Create wallet",
                mainSize: .wide,
                mainAction: {
                    
                },
                mainIsBusy: false,
                supplementTitle: "What does it mean?",
                supplementSize: .wide,
                supplementAction: {
                    
                },
                isVisible: true,
                containSupplementButton: false),
            titleAction: { }
        )
        .padding(.horizontal, 40)
    }
}
