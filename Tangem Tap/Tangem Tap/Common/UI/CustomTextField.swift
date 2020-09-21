//
//  CustomtextFiels.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomTextField: UIViewRepresentable {
    
    class Coordinator: NSObject, UITextFieldDelegate {
        
        @Binding var text: String
        @Binding var isResponder : Bool?
        @Binding var actionButtonTapped: Bool
        let placeholder: String
        let decimalCount: Int?
        
        init(text: Binding<String>, placeholder: String, decimalCount: Int?,
             isResponder : Binding<Bool?>, actionButtonTapped: Binding<Bool>) {
            _text = text
            _isResponder = isResponder
            _actionButtonTapped = actionButtonTapped
            self.placeholder = placeholder
            self.decimalCount = decimalCount
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isResponder = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isResponder = false
            }
        }
        
        @objc func actionTapped() {
            self.actionButtonTapped.toggle()
        }
        
        @objc func hideKeyboard() {
            UIApplication.shared.windows.first { $0.isKeyWindow }?.endEditing(true)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let maxLength = self.decimalCount else {
                return true
            }
            
            let currentString: NSString = textField.text! as NSString
            let newString: String =
                currentString.replacingCharacters(in: range, with: string) as String
            
            
            
            var allowNew = true
            
            if let dotIndex = newString.firstIndex(of: ".") {
                let fromIndex = newString.index(after: dotIndex)
                let decimalsString = newString[fromIndex...]
                allowNew = decimalsString.count <= maxLength
            } else {
                allowNew = true
            }
            
            guard allowNew else {
                return false
            }
            
            if string == "," {
                if let text = textField.text {
                    textField.text = text + "."
                    return false
                }
            }
            
            return true
        }
        
    }
    
    @Binding var text: String
    @Binding var isResponder : Bool?
    @Binding var actionButtonTapped: Bool
    
    var isSecured : Bool = false
    var handleKeyboard : Bool = false
    var actionButton : String? =  nil
    var keyboard : UIKeyboardType = .default
    var textColor: UIColor = UIColor.tangemTapGrayDark4
    var font: UIFont = UIFont.systemFont(ofSize: 16.0)
    let placeholder: String
    let toolbarItems: [UIBarButtonItem]? = nil
    var decimalCount: Int? = nil

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.isSecureTextEntry = isSecured
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = keyboard
        textField.font = font
        textField.textColor = textColor
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        var toolbarItems =  [UIBarButtonItem]()
        if handleKeyboard {
        toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                         target: nil,
                                         action: nil),
                         UIBarButtonItem(image: UIImage(named: "keyboard.chevron.compact.down"),
                                         style: .plain,
                                         target: context.coordinator,
                                         action: #selector(context.coordinator.hideKeyboard))]
            
          
       
        }
        
        if let actionButton = actionButton {
            toolbarItems.insert(UIBarButtonItem(title: actionButton,
                                                style: .plain,
                                                target: context.coordinator,
                                                action: #selector(context.coordinator.actionTapped)),
                                at: 0)
        }
        if !toolbarItems.isEmpty {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            toolbar.items = toolbarItems
            toolbar.backgroundColor = UIColor.tangemTapBgGray
            toolbar.tintColor = UIColor.black
            textField.inputAccessoryView = toolbar
        }
        
        return textField
    }
    
    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(text: $text, placeholder: placeholder,
                           decimalCount: decimalCount, isResponder: $isResponder,
                           actionButtonTapped: $actionButtonTapped)
    }
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        uiView.text = text
        
        if isResponder ?? false {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }
    
}
