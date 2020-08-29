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
      let placeholder: String

    init(text: Binding<String>, placeholder: String, isResponder : Binding<Bool?>) {
        _text = text
        _isResponder = isResponder
        self.placeholder = placeholder
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
  }

  @Binding var text: String
  @Binding var isResponder : Bool?

  var isSecured : Bool = false
  var keyboard : UIKeyboardType
  let placeholder: String
    
  func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UIView {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 20.0))
    let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 180, height: 20.0))
    //textField.translatesAutoresizingMaskIntoConstraints = false
    textField.isSecureTextEntry = isSecured
    textField.autocapitalizationType = .none
    textField.autocorrectionType = .no
    textField.keyboardType = keyboard
    textField.font = UIFont.systemFont(ofSize: 16.0)
    textField.textColor = UIColor.tangemTapGrayDark4
    textField.delegate = context.coordinator
    textField.placeholder = placeholder
    view.addSubview(textField)
//    let constraints = [
//        textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//        textField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//        textField.topAnchor.constraint(equalTo: view.topAnchor),
//        textField.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//       // textField.widthAnchor.constraint(equalTo: view.widthAnchor)
//    ]
//    textField.addConstraints(constraints)
      return view
  }

  func makeCoordinator() -> CustomTextField.Coordinator {
    return Coordinator(text: $text, placeholder: placeholder, isResponder: $isResponder)
  }

  func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<CustomTextField>) {
      let textView = uiView.subviews.first! as! UITextField
       textView.text = text
       if isResponder ?? false {
        DispatchQueue.main.async {
             textView.becomeFirstResponder()
        }
       }
  }

}
