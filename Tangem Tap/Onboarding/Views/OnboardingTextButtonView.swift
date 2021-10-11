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
    let size: ButtonLayout
    let action: (() -> Void)?
    let isBusy: Bool
    var isEnabled: Bool
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
    let mainSize: ButtonLayout
    let mainAction: (() -> Void)?
    let mainIsBusy: Bool
    var mainColor: ButtonColorStyle = .green
    var mainButtonSystemIconName: String = ""
    let isMainEnabled: Bool
    
    let supplementTitle: LocalizedStringKey
    let supplementSize: ButtonLayout
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
    var checkmarkText: LocalizedStringKey? = nil
    var isCheckmarkChecked: Binding<Bool> = .constant(false)
    
    @ViewBuilder
    var buttons: some View {
        VStack(spacing: 10) {
            let mainSettings = buttonsSettings.main
            TangemButton(title: mainSettings.title,
                         systemImage: mainSettings.systemIconName,
                         iconPosition: mainSettings.iconPosition) {
                withAnimation {
                    mainSettings.action?()
                }
            }
            .buttonStyle(TangemButtonStyle(colorStyle: mainSettings.color,
                                           layout: mainSettings.size,
                                           isDisabled: !mainSettings.isEnabled,
                                           isLoading: mainSettings.isBusy))
            
            if let settings = buttonsSettings.supplement {
//            if buttonsSettings.containSupplementButton {
                TangemButton(title: settings.title) {
                    settings.action?()
                }
                .opacity(settings.isVisible ? 1.0 : 0.0)
                .buttonStyle(TangemButtonStyle(colorStyle: settings.color,
                                               layout: settings.size,
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
            
            if let checkmarkText = self.checkmarkText {
                HStack {
                    CheckmarkSwitch(isChecked: isCheckmarkChecked,
                                    settings: .defaultRoundedRect())
                        .frame(size: .init(width: 26, height: 26))
                    Text(checkmarkText).bold()
                }
                
                Spacer()
            }
            
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
