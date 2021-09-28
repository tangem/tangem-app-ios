//
//  OnboardingTextButtonView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemButtonSettings {
    let title: LocalizedStringKey
    let size: ButtonSize
    let action: (() -> Void)?
    let isBusy: Bool
    let isEnabled: Bool
    let isVisible: Bool
    
    var color: ButtonColorStyle = .green
    var customIconName: String = ""
    var systemIconName: String = ""
    var iconPosition: TangemButton.IconPosition = .trailing
    
}

struct OnboardingBottomButtonsSettings {
    let main: TangemButtonSettings
    
    var supplement: TangemButtonSettings? = nil
}

struct ButtonsSettings {
    let mainTitle: LocalizedStringKey
    let mainSize: ButtonSize
    let mainAction: (() -> Void)?
    let mainIsBusy: Bool
    var mainColor: ButtonColorStyle = .green
    var mainButtonSystemIconName: String = ""
    let isMainEnabled: Bool
    
    let supplementTitle: LocalizedStringKey
    let supplementSize: ButtonSize
    let supplementAction: (() -> Void)?
    var supplementColor: ButtonColorStyle = .transparentWhite
    let isVisible: Bool
    let containSupplementButton: Bool
}

struct OnboardingTextButtonView: View {
    
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var textOffset: CGSize = .zero
//    let buttonsSettings: ButtonsSettings
    let buttonsSettings: OnboardingBottomButtonsSettings
    
    let titleAction: (() -> Void)?
    
    @ViewBuilder
    var buttons: some View {
        VStack(spacing: 10) {
            let mainSettings = buttonsSettings.main
            TangemButton(isLoading: mainSettings.isBusy,
                         title: mainSettings.title,
                         systemImage: mainSettings.systemIconName,
                         size: mainSettings.size,
                         iconPosition: mainSettings.iconPosition) {
                withAnimation {
                    mainSettings.action?()
                }
            }
            .buttonStyle(TangemButtonStyle(color: mainSettings.color,
                                           font: .system(size: 17, weight: .semibold),
                                           isDisabled: !mainSettings.isEnabled))
            
            if let settings = buttonsSettings.supplement {
//            if buttonsSettings.containSupplementButton {
                TangemButton(isLoading: false,
                             title: settings.title,
                             size: settings.size) {
                    settings.action?()
                }
                .opacity(settings.isVisible ? 1.0 : 0.0)
                .buttonStyle(TangemButtonStyle(color: settings.color,
                                               font: .system(size: 17, weight: .semibold),
                                               isDisabled: !settings.isEnabled))
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
                .padding(.bottom, buttonsSettings.supplement != nil ? 16 : 20)
                
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
            buttonsSettings:
                .init(main: TangemButtonSettings(
                        title: "Create wallet",
                        size: .wide,
                        action: {},
                        isBusy: false,
                        isEnabled: true,
                        isVisible: true),
                      supplement: TangemButtonSettings(
                        title: "What does it mean?",
                        size: .wide,
                        action: {},
                        isBusy: false,
                        isEnabled: false,
                        isVisible: true,
                        color: .grayAlt,
                        systemIconName: "plus",
                        iconPosition: .leading
                      )
                ),
            titleAction: { }
//                .init(
//                mainTitle: "Create wallet",
//                mainSize: .wide,
//                mainAction: {
//
//                },
//                mainIsBusy: false,
//                isMainEnabled: true,
//                supplementTitle: "What does it mean?",
//                supplementSize: .wide,
//                supplementAction: {
//
//                },
//                isVisible: true,
//                containSupplementButton: false),
//            titleAction: { }
        )
        .padding(.horizontal, 40)
    }
}
