//
//  IssueIdViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemSdk
import AVFoundation

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
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        sdk.config.legacyMode = Utils().needLegacyMode
        return sdk
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
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            let alert = UIAlertController(title: "Camera access denied", message: "You have not given access to your camera, please adjust your privacy settings", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                               if UIApplication.shared.canOpenURL(url) {
                                   UIApplication.shared.open(url, options: [:], completionHandler: nil)
                               }
                           }
                       })
            alert.addAction(UIAlertAction(title: Localizations.generalCancel, style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        default:
            openCamera()
        }
    }
    
    func openCamera() {
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
        if state == .write {
            imageView.isUserInteractionEnabled = false
            firstNameText.isEnabled = false
            lastNameText.isEnabled = false
            dobText.isEnabled = false
            sexSelector.isEnabled = false
        }
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
        let jpgImage = image.jpegData(compressionQuality: 0.9)!
        let birthDay = (dobText.inputView as! UIDatePicker).date
        
        confirmButton.showActivityIndicator()
        let issueTask = ConfirmIdTask(fullname: "\(firstName) \(lastName)", birthDay: birthDay, gender: gender, photo: jpgImage)
        issueTask.card = card
        tangemSdk.startSession(with: issueTask, cardId: nil, initialMessage: Message(header: "Hold your iPhone near the Issuer card", body: nil) ) { result in
            switch result {
            case .success(let response):
                self.confirmIdResponse = response
                self.state = .write
                self.updateUI()
            case .failure(let error):
                if !error.isUserCancelled {
                    Analytics.log(error: error)
                    self.handleGenericError(error)
                }
            }
              self.confirmButton.hideActivityIndicator()
        }
    }
    
    private func write() {
        guard let confirmResponse = self.confirmIdResponse else {
            return
        }
        
        let cardId = Data(hex: card.cardID)
        let issuerKey = Data(hex: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
        let issuerDataCounter = 1
        let startingSignature = Secp256k1Utils.sign(cardId + issuerDataCounter.bytes4 + confirmResponse.issuerData.count.bytes2, with: issuerKey)!
        let finalizingSignature =  Secp256k1Utils.sign(cardId + confirmResponse.issuerData + issuerDataCounter.bytes4, with: issuerKey)!
        
        confirmButton.showActivityIndicator()
        
        let writeCommand = WriteIssuerExtraDataCommand(issuerData: confirmResponse.issuerData,
                                                 issuerPublicKey: nil,
                                                 startingSignature: startingSignature,
                                                 finalizingSignature: finalizingSignature,
                                                 issuerDataCounter: issuerDataCounter)
        
        tangemSdk.startSession(with: writeCommand, cardId: card.cardID, initialMessage: Message(header: "Hold your iPhone near the ID card", body: nil)) { result in
            switch result {
            case .success:
                if let idEngine = self.card.cardEngine as? ETHIdEngine {
                    idEngine.send(signature: confirmResponse.signature) { result, error in
                        DispatchQueue.main.async {
                            self.confirmButton.hideActivityIndicator()
                            if result {
                                //todo go to read main screen
                                self.handleSuccess(message: "Id issued succesfully", completion: {
                                    self.dismiss(animated: true, completion: nil)
                                    UIApplication.navigationManager().navigationController.popToRootViewController(animated: true)
                                })
                            } else {
                                let errMsg = error?.localizedDescription ?? ""
                                if let error = error {
                                    Analytics.log(error: error)
                                }
                                self.handleTXSendError(message: "\(errMsg)")
                            }
                        }
                    }
                }
            case .failure(let error):
                self.confirmButton.hideActivityIndicator()
                 if !error.isUserCancelled {
                    Analytics.log(error: error)
                    self.handleGenericError(error)
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
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
