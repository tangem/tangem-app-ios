//
//  OnboardingAccessCodeView.swift
//  Tangem
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

struct OnboardingAccessCodeViewModel: Identifiable {
    let id: UUID = .init()
    let successHandler: (String) -> Void
}

struct OnboardingAccessCodeView: View {
    let viewModel: OnboardingAccessCodeViewModel

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
            VStack(alignment: .leading, spacing: 20) {
                ForEach(0 ..< 3) { index in
                    let feature = ViewState.featuresDescription[index]
                    HStack(alignment: .customTop, spacing: 20) {
                        Image(feature.icon)
                            .alignmentGuide(.customTop) { d in d[VerticalAlignment.top] - 4 }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(feature.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.tangemGrayDark6)
                            Text(feature.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.tangemGrayDark2)
                                .fixedSize(horizontal: false, vertical: true)
                                .alignmentGuide(.customTop) { d in d[VerticalAlignment.top] }
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.isSmallScreen ? 0 : 10)
        case .inputCode, .repeatCode:
            inputContent
        }
    }

    @ViewBuilder
    var inputContent: some View {
        Text("onboarding_access_code_hint")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.tangemGrayDark6)
            .padding(.bottom, 32)
            .padding(.top, 13)
            .multilineTextAlignment(.center)
        CustomPasswordTextField(placeholder: "details_manage_security_access_code",
                                color: .tangemGrayDark6,
                                password: state == .inputCode ? $firstEnteredCode : $secondEnteredCode,
                                onCommit: {})
            .frame(height: 44)
    }

    var body: some View {
        VStack {
            Text(state.title)
                .minimumScaleFactor(0.3)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .foregroundColor(.tangemGrayDark6)
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

            content

            Text(error.description)
                .id("error_\(error.rawValue)")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .regular))
                .opacity(error.errorOpacity)
                .foregroundColor(.tangemCritical)
            Spacer()
            TangemButton(title: state.buttonTitle) {
                let nextState: ViewState
                switch state {
                case .intro:
                    nextState = .inputCode
                case .inputCode:
                    guard isAccessCodeValid() else {
                        return
                    }

                    Analytics.log(.accessCodeEntered)
                    nextState = .repeatCode
                case .repeatCode:
                    guard isAccessCodeValid() else {
                        return
                    }

                    Analytics.log(.accessCodeReEntered)
                    viewModel.successHandler(secondEnteredCode)
                    return
                }

                state = nextState
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .wide))
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 40)
        .keyboardAdaptive(animated: .constant(false))
        .onDisappear {
            DispatchQueue.main.async {
                self.error = .none
            }
        }
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
    var backgroundColor: Color = .tangemBgGray2

    var password: Binding<String>

    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = { }
    /// iOS15+
    var shouldBecomeFirstResponder: Bool = true

    @State var isSecured: Bool = true

    @ViewBuilder
    var input: some View {
        if #available(iOS 15.0, *) {
            FocusableTextField(isSecured: isSecured,
                               shouldBecomeFirstResponder: shouldBecomeFirstResponder,
                               placeholder: placeholder,
                               text: password,
                               onEditingChanged: onEditingChanged,
                               onCommit: onCommit)
        } else {
            legacyInput
        }
    }

    @ViewBuilder
    private var legacyInput: some View {
        if isSecured {
            SecureField(placeholder,
                        text: password,
                        onCommit: onCommit)
        } else {
            TextField(placeholder,
                      text: password,
                      onEditingChanged: onEditingChanged,
                      onCommit: onCommit)
        }
    }

    var body: some View {
        GeometryReader { geom in
            HStack(spacing: 8) {
                input
                    .autocapitalization(.none)
                    .transition(.opacity)
                    .foregroundColor(color)
                    .keyboardType(.default)
                    .disableAutocorrection(true)
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
            .background(Color.tangemBgGray2)
            .cornerRadius(10)
        }
    }
}

@available(iOS 15.0, *)
private extension CustomPasswordTextField {
    enum Field: Hashable {
        case secure
        case plain
    }

    struct FocusableTextField: View {
        let isSecured: Bool
        let shouldBecomeFirstResponder: Bool
        let placeholder: LocalizedStringKey
        let text: Binding<String>
        var onEditingChanged: (Bool) -> Void = { _ in }
        var onCommit: () -> Void = {}

        @FocusState private var focusedField: Field?

        var body: some View {
            ZStack {
                if isSecured {
                    SecureField(placeholder,
                                text: text,
                                onCommit: onCommit)
                        .focused($focusedField, equals: .secure)
                } else {
                    TextField(placeholder,
                              text: text,
                              onEditingChanged: onEditingChanged,
                              onCommit: onCommit)
                        .focused($focusedField, equals: .plain)
                }
            }
            .keyboardType(.default)
            .onAppear(perform: onAppear)
            .onChange(of: isSecured) { newValue in
                setFocus(for: newValue)
            }
        }

        private func setFocus(for value: Bool) {
            focusedField = value ? .secure : .plain
        }

        private func onAppear() {
            if shouldBecomeFirstResponder {
                // Works only with huge delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    setFocus(for: isSecured)
                }
            }
        }
    }
}

extension OnboardingAccessCodeView {
    enum ViewState: String {
        case intro
        case inputCode
        case repeatCode

        var title: LocalizedStringKey {
            switch self {
            case .intro, .inputCode: return "onboarding_access_code_intro_title"
            case .repeatCode: return "onboarding_access_code_repeat_code_title"
            }
        }

        var buttonTitle: LocalizedStringKey {
            switch self {
            case .intro: return "common_continue"
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
                      icon: "access_code_feature_3"),
            ]
        }
    }

    enum AccessCodeError: String {
        case none
        case tooShort
        case dontMatch

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
}

struct OnboardingAccessCodeView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingAccessCodeView(viewModel: .init(successHandler: { _ in }))
    }
}
