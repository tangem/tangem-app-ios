//
//  IssueIdViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemKit
import TangemSdk

@available(iOS 13.0, *)
class IssueIdViewController: UIViewController, DefaultErrorAlertsCapable {
    
    enum IssueState {
        case confirm
        case write
    }
    
    private var state = IssueState.confirm
    
    public var card: CardViewModel!
    private var photoTaken = false
    private var confirmIdResponse: ConfirmIdResponse?
    lazy var cardManager: CardManager = {
        let manager = CardManager()
        manager.config.legacyMode = Utils().needLegacyMode
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapRecognizer)
        
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            let tapRecognizer = UITapGestureRecognizer()
            tapRecognizer.numberOfTouchesRequired = 1
            tapRecognizer.addTarget(self, action: #selector(addPhotoTapped))
            imageView.addGestureRecognizer(tapRecognizer)
        }
    }
    
    @IBOutlet weak var firstNameText: UITextField! {
        didSet {
            firstNameText.delegate = self
        }
    }
    
    @IBOutlet weak var lastNameText: UITextField! {
        didSet {
            lastNameText.delegate = self
        }
    }
    
    @IBOutlet weak var dobText: UITextField! {
        didSet {
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            datePicker.date = Date()
            datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
            dobText.inputView = datePicker
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                             UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))]
            
            dobText.inputAccessoryView = toolbar
            dobText.delegate = self
        }
    }
    @IBOutlet weak var sexSelector: UISegmentedControl!
    
    @IBOutlet weak var confirmButton: UIButton!  {
        didSet {
            confirmButton.layer.cornerRadius = 30.0
            confirmButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            confirmButton.layer.shadowRadius = 5.0
            confirmButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            confirmButton.layer.shadowColor = UIColor.black.cgColor
            confirmButton.layer.shadowOpacity = 0.08
            confirmButton.setTitleColor(UIColor.lightGray, for: .disabled)
        }
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        switch state {
        case .confirm:
            confirm()
        case .write:
            write()
        }
    }
    
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dobText.text = dateFormatter.string(from: datePicker.date)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func addPhotoTapped() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.sourceType = .camera
        pickerController.cameraDevice = .front
        self.present(pickerController, animated: true)
    }
    
    func shake(_ view: UIView) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.error)
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.05
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: view.center.x - 5, y: view.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: view.center.x + 5, y: view.center.y))
        view.layer.add(animation, forKey: "position")       
    }
    
    func updateUI() {
        let title = state == .confirm ? "Confirm" : "Issue Id"
        confirmButton.setTitle(title, for: .normal)
    }
    
    private func confirm() {
        guard let image = imageView.image, photoTaken else {
            shake(imageView)
            return
        }
        
        guard let firstName = firstNameText.text, !firstName.isEmpty else {
            shake(firstNameText)
            return
        }
        
        guard let lastName = lastNameText.text, !lastName.isEmpty  else {
            shake(lastNameText)
            return
        }
        
        guard let dob = dobText.text, !dob.isEmpty  else {
            shake(dobText)
            return
        }
        
        
        let gender = sexSelector.selectedSegmentIndex == 0 ? "F" : "M"
        let jpgImage = UIImageJPEGRepresentation(image, 0.9)!
        let birthDay = (dobText.inputView as! UIDatePicker).date
        
        confirmButton.showActivityIndicator()
        let issueTask = ConfirmIdTask(fullname: "\(firstName) \(lastName)", birthDay: birthDay, gender: gender, photo: jpgImage)
        issueTask.card = card
        cardManager.runTask(issueTask) {[weak self] result in
            switch result {
            case .event(let response):
                self?.confirmIdResponse = response
                self?.state = .write
                self?.updateUI()
            case .completion(let error):
                if let error = error, !error.isUserCancelled {
                    self?.handleGenericError(error)
                }
                self?.confirmButton.hideActivityIndicator()
            }
        }
    }
    
    private func write() {
        guard let confirmResponse = self.confirmIdResponse else {
            return
        }
        
        let cardId = Data(hexString: card.cardID)
        let issuerKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
        let issuerDataCounter = 1
        let startingSignature = CryptoUtils.signSecp256k1(cardId + issuerDataCounter.bytes4 + confirmResponse.issuerData.count.bytes2, with: issuerKey)!
        let finalizingSignature =  CryptoUtils.signSecp256k1(cardId + confirmResponse.issuerData + issuerDataCounter.bytes4, with: issuerKey)!
        
        confirmButton.showActivityIndicator()
        cardManager.writeIssuerExtraData(cardId: card.cardID,
                                         issuerData: confirmResponse.issuerData,
                                         startingSignature: startingSignature,
                                         finalizingSignature: finalizingSignature,
                                         issuerDataCounter: issuerDataCounter) {[weak self] writeResult in
                                            switch writeResult {
                                            case .event:
                                                if let idEngine = self?.card.cardEngine as? ETHIdEngine {
                                                    idEngine.send(signature: confirmResponse.signature) { result, error in
                                                        DispatchQueue.main.async {
                                                            self?.confirmButton.hideActivityIndicator()
                                                            if result {
                                                                //todo go to read main screen
                                                                self?.handleSuccess(message: "Id issued succesfully", completion: {  UIApplication.navigationManager().navigationController.popToRootViewController(animated: true)
                                                                })
                                                            } else {
                                                                let errMsg = (error as? String ?? error?.localizedDescription) ?? ""
                                                                self?.handleTXSendError(message: "\(errMsg)")
                                                            }
                                                        }
                                                    }
                                                }
                                            case .completion(let error):
                                                if let error = error, !error.isUserCancelled {
                                                    self?.confirmButton?.hideActivityIndicator()
                                                    self?.handleGenericError(error)
                                                }
                                                
                                            }
        }
    }
}

@available(iOS 13.0, *)
extension IssueIdViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextResponder = view.nextKeyboardResponder() {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
}

@available(iOS 13.0, *)
extension IssueIdViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            let scaled = resize(image)
            imageView.image = scaled
            photoTaken = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func resize(_ image:UIImage) -> UIImage {
        let newSize = CGSize(width: 200, height: 200)
        let minImageDimension = min(image.size.width, image.size.height)
        let ratio = minImageDimension/newSize.width
        let scaledWidth = image.size.width / ratio
        let scaledHeight = image.size.height / ratio
        let xOffset = 0 - (scaledWidth - newSize.width)/2
        let yOffset = 0 - (scaledHeight - newSize.height)/2
        let drawPoint = CGPoint(x: xOffset, y: yOffset)
        let drawRect = CGRect(origin: drawPoint, size: CGSize(width: scaledWidth, height: scaledHeight))
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            image.draw(in: drawRect)
        }
    }
}

@available(iOS 13.0, *)
extension IssueIdViewController: UINavigationControllerDelegate {
    
}
