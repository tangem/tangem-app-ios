//
//  ExtractViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif
import TangemKit

public enum NFCState {
    case active
    case signed
    case processing
    case none
}

@available(iOS 13.0, *)
class ExtractViewController: ModalActionViewController {
    
    var card: Card!
    var onDone: (()-> Void)?
    
    private let stateLockQueue = DispatchQueue(label: "Tangem.ExtractViewController.stateLockQueue")
    private var _state: NFCState = .none
    var state: NFCState  {
        get {
            stateLockQueue.sync {
                return _state
            }
        }
        set {
            stateLockQueue.sync {
                _state = newValue
            }
        }
    }

    private var signApdu: NFCISO7816APDU?
    
    @IBOutlet weak var amountText: UITextField! {
        didSet {
            amountText.delegate = self
        }
    }
    
    @IBOutlet weak var amountStackView: UIStackView!
    @IBOutlet weak var addressSeparator: UIView!
    @IBOutlet weak var amountSeparator: UIView!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var targetStackView: UIStackView!
    @IBOutlet weak var feeControl: UISegmentedControl!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var amountUnitsLabel: UILabel!
    @IBOutlet weak var blockchainNameLabel: UILabel!
    @IBOutlet weak var targetAddressText: UITextField! {
        didSet {
            targetAddressText.delegate = self
        }
    }
    @IBOutlet weak var includeFeeSwitch: UISwitch!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var pasteTargetAdressButton: UIButton!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var cardInfoContainer: UIStackView!
    
    private var readerSession: NFCTagReaderSession?
    private var validatedAmount: String?
    private var validatedTarget: String?
    private var validatedFee: String?
    private var bgLayer = CALayer()
    private var pasteLayer = CALayer()
    private var triangleLayer = CAShapeLayer()
    private var feeTimer: Timer?
    private var feeTime = Date(timeIntervalSince1970: TimeInterval(1.0))
    
    private lazy var recognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTouchesRequired = 1
        recognizer.addTarget(self, action: #selector(viewDidTap))
        return recognizer
    }()
    
    private var sessionTimer: Timer?
    private func startSessionTimer() {
        DispatchQueue.main.async {
            self.sessionTimer?.invalidate()
            self.sessionTimer = Timer.scheduledTimer(timeInterval: 59.0, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    private var tagTimer: Timer?
    private func startTagTimer() {
        DispatchQueue.main.async {
            self.tagTimer?.invalidate()
            self.tagTimer = Timer.scheduledTimer(timeInterval: 19.0, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    @objc func timerTimeout() {
        guard let session = self.readerSession,
            (state == .active || state == .processing)   else { return }
        
        if state == .processing {
            state = .none
            return
        }
        session.invalidate(errorMessage: "Session timeout")
    }
    
    @objc func viewDidTap() {
        targetAddressText.resignFirstResponder()
        amountText.resignFirstResponder()
    }
    
    private var fee: (min: String, normal: String, max: String)? {
        didSet {
            feeTime = Date()
        }
    }
    @IBAction func feeIncludeChanged(_ sender: UISwitch, forEvent event: UIEvent) {
        validateInput()
    }
    
    @IBAction func feePresetChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        if fee == nil {
            tryUpdateFeePreset()
            return
        }
        updateFee()
        validateInput()
    }
    @IBAction func pasteTapped(_ sender: Any, forEvent event: UIEvent) {
        if let pasteAddress = getPasteAddress() {
              targetAddressText.text = pasteAddress
              tryUpdateFeePreset()
        } else {
            pasteTargetAdressButton.isEnabled = false
        }
    }
    
    @IBAction func targetChanged(_ sender: UITextField, forEvent event: UIEvent) {
        setError(false, for: sender)
        tryUpdateFeePreset()
    }
    @IBAction func amountChanged(_ sender: UITextField, forEvent event: UIEvent) {
        setError(false, for: sender)
        tryUpdateFeePreset()
    }
    
    @IBAction func scanTapped() {
        guard state == .none, validateInput() else {
            return
        }
        
        guard feeTime.distance(to: Date()) < TimeInterval(60.0) else {
            tryUpdateFeePreset()
            return
        }
        
        signApdu = buildSignApdu()
        guard signApdu != nil else {
            return
        }
        
        btnSend.setAttributedTitle(NSAttributedString(string: ""), for: .normal)
        btnSend.showActivityIndicator()
        addLoadingView()
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        readerSession?.alertMessage = "Hold your iPhone near a Tangem card"
        readerSession?.begin()
        state = .active
    }
    
    func buildSignApdu() -> NFCISO7816APDU? {
        let cProvider = self.card.cardEngine as! CoinProvider
        guard let hashToSign = cProvider.getHashForSignature(amount: self.validatedAmount!, fee: self.validatedFee!, includeFee: self.includeFeeSwitch.isOn, targetAddress: self.validatedTarget!) else {
            self.handleTXBuildError()
            return nil
        }
                
        let cardId = self.card.cardID.asciiHexToData()!
        let hSize = [UInt8(hashToSign.count)]
        
        var tlvData = [
            CardTLV(.pin, value: "000000".sha256().asciiHexToData()),
            CardTLV(.cardId, value: cardId),
            CardTLV(.pin2, value: "000".sha256().asciiHexToData()),
            CardTLV(.transactionOutHashSize, value: hSize),
            CardTLV(.transactionOutHash, value: hashToSign.bytes)]
        
        let signMethods = self.card.supportedSignMethods
        
        if signMethods.contains(.issuerSign) {
            let issuerSignature: [UInt8] = []
            if issuerSignature.isEmpty {
                if !signMethods.contains(.signHashes) {
                    self.handleTXNotSignedByIssuer()
                    return nil
                }
            } else {
                tlvData.append(CardTLV(.issuerTxSignature, value: issuerSignature))
            }
        }
        
        let commandApdu = CommandApdu(with: .sign, tlv: tlvData)
        let signApduBytes = commandApdu.buildCommand()
        let signApdu = NFCISO7816APDU(data: Data(bytes: signApduBytes))!
        return signApdu
    }
    
    func addLoadingView() {
        if let window = self.view.window {
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            view.addSubview(indicator)
            view.tag = 0781
            indicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            indicator.startAnimating()
            window.addSubview(view)
            window.bringSubview(toFront: view)
        }
    }
    
    func removeLoadingView() {
        if let window = self.view.window,
            let view = window.viewWithTag(0781) {
            view.removeFromSuperview()
        }
    }
    
    func updateFee() {
            switch feeControl.selectedSegmentIndex {
            case 0:
                feeLabel.text = fee?.min ?? ""
            case 1:
                feeLabel.text = fee?.normal ?? ""
            case 2:
                feeLabel.text = fee?.max ?? ""
            default:
                feeLabel.text = ""
            }
       
        
        if !feeLabel.text!.isEmpty {
            feeLabel.text! += " \(card.walletUnits)"
        } else {
            feeLabel.text = Constants.feeStub
        }
    
            
        validatedFee = feeLabel.text
        feeLabel.hideActivityIndicator()
        //  print("min fee: \(fee?.min) normal fee: \(fee?.normal) max fee \(fee?.max)")
    }
    
    @discardableResult
    func validateInput(skipFee: Bool = false) -> Bool {
        validatedAmount = ""
        validatedFee = ""
        validatedTarget = ""
       
        guard let target = targetAddressText.text,
            validate(address: target) else {
                setError(true, for: targetAddressText )
                btnSendSetEnabled(false)
                return false
         }
        
        guard let amount = amountText.text?.replacingOccurrences(of: ",", with: "."),
            !amount.isEmpty,
            let amountValue = Decimal(string: amount),
            amountValue > 0,
            let total = Decimal(string: card.walletValue) else {
                 setError(true, for: amountText )
                btnSendSetEnabled(false)
                return false
        }
        
        if !skipFee {
            guard let fee = feeLabel.text?.remove(" \(card.walletUnits)"),
                let feeValue = Decimal(string: fee),
                !fee.isEmpty else {
                    btnSendSetEnabled(false)
                    return false
            }
            
            let valueToSend = includeFeeSwitch.isOn ? amountValue : amountValue + feeValue
            guard total >= valueToSend else {
                 setError(true, for: amountText )
                btnSendSetEnabled(false)
                return false
            }
            
            validatedFee = fee
        }
             
        setError(false, for: targetAddressText )
        setError(false, for: amountText )
        validatedAmount = amount
        validatedTarget = target
        btnSendSetEnabled(true)
        updateSendButtonSubtitle()
        return true
    }
    
    func getPasteAddress() -> String? {
        if let pasteString = UIPasteboard.general.string,
                   validate(address: pasteString) {
                  return pasteString
               }
        return  nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = getPasteAddress() {
            pasteTargetAdressButton.isEnabled = true
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnSend.layer.cornerRadius = 8.0
        btnSendSetEnabled(false)
        cardLabel.text = card.cardID
        amountLabel.text = "\(card.walletValue) \(card.cardEngine.walletUnits)"
        
        
        includeFeeSwitch.transform = CGAffineTransform.identity.translatedBy(x: -0.1*includeFeeSwitch.frame.width, y: 0).scaledBy(x: 0.8, y: 0.8)
      
        //        let addressText = NSMutableAttributedString(string: "Address: \(card.address)")
        //        addressText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: 8))
        
        addressLabel.text = card.address
        feeLabel.text = Constants.feeStub
        amountText.text = card.walletValue
        
        let traits = (self.card.cardEngine as! CoinProvider).coinTraitCollection
        includeFeeSwitch.isHidden = !traits.contains(CoinTrait.allowsFeeInclude)
        feeControl.isHidden = !traits.contains(CoinTrait.allowsFeeSelector)
        
        blockchainNameLabel.text = card.blockchain.rawValue.uppercased()
        amountUnitsLabel.text = card.walletUnits.uppercased()
        view.addGestureRecognizer(recognizer)
        
        topStackView.setCustomSpacing(20.0, after: amountStackView)
    }
    
    private func validate(address: String) -> Bool {
        guard !address.isEmpty,
            address != card.cardEngine.walletAddress,
            (card.cardEngine as! CoinProvider).validate(address: address)
            else {
                return false
        }
        
        return true
    }
    
    
    func updateSendButtonSubtitle() {
        guard btnSend.isEnabled else {
            return
        }
        
        let sendTitle = "SEND"
        guard let amount = Decimal(string: validatedAmount ?? ""),
            let fee = Decimal(string: validatedFee ?? "") else {
                if btnSend.titleLabel?.text != sendTitle {
                    UIView.performWithoutAnimation {
                         btnSend.setTitle(sendTitle, for: .normal)
                        btnSend.layoutIfNeeded()
                    }
                }
                return
        }
        
        let valueToSend = includeFeeSwitch.isOn ? amount : amount + fee
        let rounded = valueToSend.rounded(blockchain: card.blockchain)
        guard valueToSend > 0 else {
            if btnSend.titleLabel?.text != sendTitle {
               btnSend.setTitle(sendTitle, for: .normal)
            }
            return
        }
        
        let titleFont = UIFont(name: "SairaCondensed-ExtraBold", size: 20)!
        let subtitleFont = UIFont(name: "SairaCondensed-Regular", size: 12)!
        
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.alignment = .center
        titleParagraph.maximumLineHeight = 24

    
        let subtitleParagraph = NSMutableParagraphStyle()
        subtitleParagraph.alignment = .center
        subtitleParagraph.maximumLineHeight = 12
        
        let titleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: titleParagraph,
                                                          NSAttributedString.Key.foregroundColor: UIColor.white,
                                                          NSAttributedString.Key.font: titleFont]
        
        let subtitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: subtitleParagraph,
                                                                 NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                 NSAttributedString.Key.font: subtitleFont]
        
        let titleText = NSMutableAttributedString(string: "\(sendTitle)", attributes: titleAttributes)
        let subtitleText = NSMutableAttributedString(string: "\(valueToSend) \(card.walletUnits)", attributes: subtitleAttributes)
        titleText.append(NSAttributedString(string: "\n"))
        titleText.append(subtitleText)
    
        UIView.performWithoutAnimation {
            btnSend?.setAttributedTitle(titleText, for: .normal)
             btnSend.layoutIfNeeded()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addBgLayers()
    }
    
    
    private func addBgLayers(){
        
        let color = UIColor.init(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0).cgColor
        let padding = CGFloat(16.0)
        
        
        bgLayer.backgroundColor = color
        let converted = topStackView.convert(cardInfoContainer.frame, to: view)
        bgLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: converted.height + converted.minY + padding)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: view.center.x-50, y: converted.maxY + padding))
        path.addLine(to: CGPoint(x: view.center.x+50, y: converted.maxY + padding))
        path.addLine(to: CGPoint(x: view.center.x, y: converted.maxY + 16 + padding))
        path.close()
        triangleLayer.fillColor = color
        triangleLayer.path = path.cgPath
        
        //let convertedPasteFrame =  topStackView.convert(targetStackView.convert(pasteTargetAddressContainer.frame, to: topStackView), to: view)
        // pasteLayer.frame = CGRect(x: 0, y: convertedPasteFrame.minY, width: view.frame.width, height: convertedPasteFrame.height)
        // pasteLayer.backgroundColor = color
        
        if bgLayer.superlayer == nil {
            view.layer.insertSublayer(triangleLayer, at: 0)
            view.layer.insertSublayer(bgLayer, at: 0)
            view.layer.insertSublayer(pasteLayer, at: 0)
        }
        
        bgLayer.setNeedsLayout()
        triangleLayer.setNeedsLayout()
        // pasteLayer.setNeedsLayout()
    }
    
    
    func tryUpdateFeePreset() {
        btnSendSetEnabled(false)
        feeTimer?.invalidate()
        feeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { [weak self] _ in
            guard let self = self else {
                return
            }
           
            guard self.validateInput(skipFee: true),
                let targetAddress = self.validatedTarget,
                let amount = self.validatedAmount  else {
                    self.fee = nil
                    self.updateFee()
                    return
            }
            
            self.feeLabel.showActivityIndicator()
            
            let cProvider = self.card.cardEngine as! CoinProvider
            cProvider.getFee(targetAddress: targetAddress, amount: amount) {[weak self] fee in
                self?.fee = fee
                DispatchQueue.main.async {
                    self?.updateFee()
                    self?.validateInput()
                }
            }
        })
    }
    
    private func setError(_ error: Bool, for textField: UITextField) {
        
         let separatorColor = UIColor.init(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
         let textColor = UIColor.init(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
        
//        textField.layer.borderColor = error ? UIColor.red.cgColor : UIColor.clear.cgColor
//        textField.layer.borderWidth = error ? 1.0 : 0.0
//        textField.layer.cornerRadius = error ? 8.0 : 0.0
        textField.textColor = error ? UIColor.red : textColor
        
        if textField == amountText {
               amountSeparator.backgroundColor = error ? UIColor.red : separatorColor
        } else if textField == targetAddressText {
            addressSeparator.backgroundColor = error ? UIColor.red : separatorColor
        }
    }
}


@available(iOS 13.0, *)
extension ExtractViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
       startSessionTimer()
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard state != .signed else {
            return
        }
        state = .none
        DispatchQueue.main.async {
            self.btnSend.hideActivityIndicator()
            self.updateSendButtonSubtitle()
            self.removeLoadingView()
        }
        
        print(error)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if case let .iso7816(tag7816) = tags.first {
            let nfcTag = tags.first!
            session.connect(to: nfcTag) {[unowned self] error in
                guard error == nil else {
                    session.invalidate(errorMessage: error!.localizedDescription)
                    return
                }
                self.startTagTimer()
                self.sendSignRequest(to: tag7816, with: session, self.signApdu!)
            }
        }
        
    }
    
    private func sendSignRequest(to tag: NFCISO7816Tag, with session: NFCTagReaderSession, _ apdu: NFCISO7816APDU) {
        tag.sendCommand(apdu: apdu) {[unowned self] (data, sw1, sw2, apduError) in
            guard apduError == nil else {
                // session.invalidate(errorMessage: apduError!.localizedDescription)
                session.alertMessage = "Hold your iPhone near a Tangem card"
                session.restartPolling()
                return
            }
            self.state = .processing
            
            let respApdu = ResponseApdu(with: data, sw1: sw1, sw2: sw2)
            
            if let cardState = respApdu.state {
                switch cardState {
                case .needPause:
                    if let remainingMilliseconds = respApdu.tlv[.pause]?.value?.intValue {
                        self.readerSession?.alertMessage = "Security delay: \(remainingMilliseconds/100) seconds"
                    }
                
                    if respApdu.tlv[.flash] != nil {
                        self.readerSession?.restartPolling()
                    } else {
                        if self.state == .none {
                            session.invalidate(errorMessage: "Session timeout")
                            return
                        }
                        self.sendSignRequest(to: tag, with: session, apdu)
                    }
                    
                case .processCompleted:
                    self.state = .signed
                    session.alertMessage = "Sign completed"
                    session.invalidate()
                    if let sign = respApdu.tlv[.signature]?.value {
                        let cProvider = self.card.cardEngine as! CoinProvider
                        cProvider.sendToBlockchain(signFromCard: sign) {[weak self] result in
                            self?.removeLoadingView()
                            self?.btnSend.hideActivityIndicator()
                            self?.updateSendButtonSubtitle()
                            if result {
                                DispatchQueue.main.async {
                                    self?.handleSuccess(completion: {
                                        self?.dismiss(animated: true) {
                                            self?.onDone?()
                                        }
                                    })
                                }
                            } else {
                                self?.state = .none
                                self?.handleTXSendError()
                            }
                            
                        }
                    }
                default:
                    session.invalidate(errorMessage: cardState.localizedDescription)
                }
            } else {
                session.invalidate(errorMessage: "Unknown card state: \(sw1) \(sw2)")
            }
            
        }
    }
    
    func btnSendSetEnabled(_ enabled: Bool) {
        btnSend.isEnabled = enabled
        UIView.animate(withDuration: 0.3) {
            self.btnSend.backgroundColor = enabled ? UIColor(red: 27.0/255.0, green: 154.0/255.0, blue: 247.0/255.0, alpha: 1) :  UIColor.init(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
               }
        }
}

@available(iOS 13.0, *)
extension ExtractViewController: DefaultErrorAlertsCapable {
    
}


@available(iOS 13.0, *)
extension ExtractViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


//MARK: Constants
@available(iOS 13.0, *)
extension ExtractViewController {
    struct Constants {
        static let feeStub = "Specify amount and address to see the fee"
    }
}
