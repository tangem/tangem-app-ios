//
//  OnboardingAccessCodeView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

fileprivate struct AccessCodeFeature {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
}

struct OnboardingAccessCodeView: View {
    
    enum ViewState: String {
        case intro, inputCode, repeatCode
        
        var title: LocalizedStringKey {
            switch self {
            case .intro, .inputCode: return "onboarding_access_code_intro_title"
            case .repeatCode: return "onboarding_access_code_repeat_code_title"
            }
        }
        
        var buttonTitle: LocalizedStringKey {
            switch self {
            case .intro: return "common_create"
            case .inputCode: return "common_continue"
            case .repeatCode: return "common_submit"
            }
        }
        
        fileprivate static var featuresDescription: [AccessCodeFeature] {
            [
                .init(title: "onboarding_access_code_feature_1_title",
                      description: "onboarding_access_code_feature_1_description",
                      icon: "access_code_feature_1"),
                .init(title: "onboarding_access_code_feature_2_title",
                      description: "onboarding_access_code_feature_2_description",
                      icon: "access_code_feature_2"),
                .init(title: "onboarding_access_code_feature_3_title",
                      description: "onboarding_access_code_feature_3_description",
                      icon: "access_code_feature_3")
            ]
        }
    }
    
    enum AccessCodeError: String {
        case none, tooShort, dontMatch
        
        var description: LocalizedStringKey {
            switch self {
            case .none: return ""
            case .tooShort: return "onboarding_access_code_too_short"
            case .dontMatch: return "onboarding_access_codes_doesnt_match"
            }
        }
        
        var errorOpacity: Double {
            switch self {
            case .none: return 0
            default: return 1
            }
        }
    }
    
    let successHandler: (String) -> Void
    
    @State private var state: ViewState = .intro
    @State private var firstEnteredCode: String = ""
    @State private var secondEnteredCode: String = ""
    @State private var error: AccessCodeError = .none
    
    @ViewBuilder
    var content: some View {
        switch state {
        case .intro:
            Spacer()
            Image("input_with_lock")
                .scaleEffect(Constants.isSmallScreen ? 0.7 : 1)
            Spacer()
            ForEach(0..<ViewState.featuresDescription.count) { index in
                let feature = ViewState.featuresDescription[index]
                HStack(spacing: 20) {
                    Image(feature.icon)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.tangemTapGrayDark6)
                        Text(feature.description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.tangemTapGrayDark2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Constants.isSmallScreen ? 0 :10)
        case .inputCode, .repeatCode:
            inputContent
        }
    }
    
    @ViewBuilder
    var inputContent: some View {
        Text("onboarding_access_code_hint")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.tangemTapGrayDark6)
            .padding(.bottom, 32)
            .padding(.top, 13)
            .multilineTextAlignment(.center)
        CustomPasswordTextField(placeholder: "Access code", color: .tangemTapGrayDark6, password: state == .inputCode ? $firstEnteredCode : $secondEnteredCode, onCommit: {
            
        })
        .frame(height: 44)
    }
    
    var body: some View {
        VStack {
            Text(state.title)
                .minimumScaleFactor(0.3)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .foregroundColor(.tangemTapGrayDark6)
                .padding(.top, Constants.isSmallScreen ? 20 : 72)
                .lineLimit(2)
                .id("title_\(state.rawValue)")
                .onTapGesture {
                    withAnimation {
                        state = .intro
                        firstEnteredCode = ""
                        secondEnteredCode = ""
                    }
                }
            
            content.transition(.opacity)
            
            Text(error.description)
                .id("error_\(error.rawValue)")
                .font(.system(size: 15, weight: .regular))
                .opacity(error.errorOpacity)
                .foregroundColor(.tangemTapCritical)
            Spacer()
            TangemButton(isLoading: false,
                         title: state.buttonTitle,
                         size: .wide) {
                let nextState: ViewState
                switch state {
                case .intro:
                    nextState = .inputCode
                case .inputCode:
                    guard isAccessCodeValid() else {
                        return
                    }
                    
                    nextState = .repeatCode
                case .repeatCode:
                    guard isAccessCodeValid() else {
                        return
                    }
                    
                    successHandler(secondEnteredCode)
                    return
                }
                
                withAnimation {
                    state = nextState
                }
            }
            .buttonStyle(TangemButtonStyle(color: .green,
                                           font: .system(size: 17, weight: .semibold),
                                           isDisabled: false))
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 40)
        .keyboardAdaptive(animated: .constant(true))
    }
    
    private func isAccessCodeValid() -> Bool {
        var error: AccessCodeError = .none
        switch state {
        case .intro: break
        case .inputCode:
            error = firstEnteredCode.count >= 4 ? .none : .tooShort
        case .repeatCode:
            error = firstEnteredCode == secondEnteredCode ? .none : .dontMatch
        }
        
        withAnimation {
            self.error = error
        }
        return error == .none
    }

}

struct CustomPasswordTextField: View {
    
    let placeholder: LocalizedStringKey
    let color: Color
    var backgroundColor: Color = .tangemTapBgGray2
    
    var password: Binding<String>
    
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = { }
    
    @State var isSecured: Bool = true
    
    @ViewBuilder
    var input: some View {
        if isSecured {
            SecureField(placeholder, text: password, onCommit: onCommit)
                .transition(.opacity)
        } else {
            TextField(placeholder, text: password, onEditingChanged: onEditingChanged, onCommit: onCommit)
                .transition(.opacity)
        }
    }
    
    var body: some View {
        GeometryReader { geom in
            HStack(spacing: 8) {
                input
                    .foregroundColor(color)
                Button(action: {
                    withAnimation {
                        isSecured.toggle()
                    }
                }, label: {
                    Image(systemName: isSecured ? "eye" : "eye.slash")
                        .foregroundColor(color)
                        .frame(width: geom.size.height, height: geom.size.height, alignment: .center)
                })
            }
            .padding(.leading, 16)
            .background(Color.tangemTapBgGray2)
            .cornerRadius(10)
        }
    }
}

struct OnboardingAccessCodeView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingAccessCodeView(successHandler: { _ in })
    }
}
