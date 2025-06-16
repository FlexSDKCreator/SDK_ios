//
//  MainMasterDetailVC
//  Companity
//
//  Created by Om Prakash Shah on 4/3/17.
//  Copyright © 2017 ksystem. All rights reserved.
//

import UIKit
import WebKit
import ObjectMapper
import FirebaseInstallations
import FirebaseMessaging
import SDWebImage
import Network
import AVFoundation
import MLKitVision
import CoreNFC
import UniformTypeIdentifiers
import Photos
import QuickLook


enum Module: Int {
    case none = 5000, companity, attendence, board, contact
}

//MARK: PROTOCOL DEFINITIONS
protocol MasterDetailActionDelegate {
    func toggleMenuPanel()
    func openMenuDrawer()
    func closeMenuDrawer()
}

public protocol CustomActionDelegate {
    func onCustomAction(customAction: CustomAction?, passResultToWeb: PassResultToWeb?)
}

public protocol PassResultToWeb {
    func onResult(error: String?, result: String?)
}

public protocol CustomAuthDelegate {
    func onAuthTokenRequest()
}

public class MainMasterDetailVC: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, BluetoothResults, NFCNDEFReaderSessionDelegate {
    
    struct FileSession {
        let url: URL
        let handle: FileHandle
        let isScoped: Bool
        let dir: URL
    }
    private var fileSessions = [String:FileSession]()
    private var imageData = [String:FileSession]()
    private var pickerDelegateKey: UInt8 = 0
    public var activePickers = [String: UIDocumentPickerViewController]()
    var previewUrl: URL?

    //START nfc, bt code
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            if (readerError.code == .readerSessionInvalidationErrorUserCanceled) {
                DispatchQueue.main.async {
                    if let nfcCallbackFn = self.nfcCallbackFn {
                        self.webView.evaluateJavaScript("\(nfcCallbackFn)('\("Canceled")')")
                    }
                }
            } else if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) {
                print("Session Invalidated: \(error.localizedDescription)")
            }
        }
        self.session = nil
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages
        {
            for record in message.records
            {
                if record.typeNameFormat == .nfcWellKnown
                {
                    let val = record.wellKnownTypeTextPayload()
                    print(val)
                    if let s = val.0,!s.isEmpty,let v = val.0
                    {
                        DispatchQueue.main.async {
                            print("didDetectNDEFs: \(v)")
                        }
                    }
                }
            }
        }
    }
    
    /// - Tag: processingNDEFTag
    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = NSLocalizedString("NFCMultiReadMsg", comment: "More than 1 tag is detected, please remove all tags and try again.")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                let errMsg = NSLocalizedString("NFCConnErrMsg", comment: "Unable to connect to tag.")
                session.alertMessage = errMsg
                session.invalidate()
                DispatchQueue.main.async {
                    if let nfcCallbackFn = self.nfcCallbackFn {
                        self.webView.evaluateJavaScript("\(nfcCallbackFn)('\(errMsg)')")
                    }
                }
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    let errMsg = NSLocalizedString("NFCCompErrMsg", comment: "Tag is not NDEF compliant")
                    session.alertMessage = errMsg
                    session.invalidate()
                    DispatchQueue.main.async {
                        if let nfcCallbackFn = self.nfcCallbackFn {
                            self.webView.evaluateJavaScript("\(nfcCallbackFn)('\(errMsg)')")
                        }
                    }
                    return
                } else if nil != error {
                    let errMsg = NSLocalizedString("NFCStatusErrMsg", comment: "Unable to query NDEF status of tag")
                    session.alertMessage = errMsg
                    session.invalidate()
                    DispatchQueue.main.async {
                        if let nfcCallbackFn = self.nfcCallbackFn {
                            self.webView.evaluateJavaScript("\(nfcCallbackFn)('\(errMsg)')")
                        }
                    }
                    return
                }
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage: String
                    if nil != error || nil == message {
                        statusMessage = error?.localizedDescription ?? NSLocalizedString("NFCReadFailMsg", comment: "Fail to read NDEF from tag")
                        DispatchQueue.main.async {
                            if let nfcCallbackFn = self.nfcCallbackFn {
                                self.webView.evaluateJavaScript("\(nfcCallbackFn)('\(statusMessage)')")
                            }
                        }
                    } else {
                        statusMessage = NSLocalizedString("NFCFoundMsg", comment: "Found 1 NDEF message")
                        DispatchQueue.main.async {
                            // Process detected NFCNDEFMessage objects.
                            var arr = []
                            for record in message!.records
                            {
                                //DispatchQueue.main.async {
                                    switch record.typeNameFormat {
                                    case .nfcWellKnown:
                                        //if url/uri type data.
                                        let uri = record.wellKnownTypeURIPayload()
                                        if(uri != nil){
                                            arr.append(uri!.absoluteString)
                                        }
                                        
                                        //if text type data.
                                        let (text, _) = record.wellKnownTypeTextPayload()
                                        if(text != nil){
                                            arr.append(text!)
                                        }
                                    case .absoluteURI:
                                        if let text = String(data: record.payload, encoding: .utf8) {
                                            //print("didDetect absoluteURI: \(text)")
                                            arr.append(text)
                                        }
                                    case .media:
                                        if let type = String(data: record.type, encoding: .utf8) {
                                            //print("didDetect media: \(type)")
                                            arr.append("media: \(type)")
                                            //simple parsing not possible as media type can be anything
                                            /*if let payloadData = record.payload as? Foundation.Data {
                                                if let payloadString = String(data: payloadData, encoding: .utf8) {
                                                    print("Parsed payload string: \(payloadString)")
                                                } else {
                                                    print("Failed to parse payload as string.")
                                                }
                                            }*/
                                        }
                                    case .nfcExternal, .empty, .unknown, .unchanged:
                                        fallthrough
                                    @unknown default:
                                        //print("didDetect fallthrough: \(record.typeNameFormat.rawValue.description)")
                                        arr.append("unsupported: \(record.typeNameFormat.rawValue.description)")
                                    }
                                //}
                            }
                            print("\(arr.count) message content")
                            if let nfcCallbackFn = self.nfcCallbackFn {
                                if let jsonData = try? JSONSerialization.data(withJSONObject: arr, options: []),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    self.webView.evaluateJavaScript("\(nfcCallbackFn)(null, \(jsonString))")
                                }
                            }
                        }
                    }
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
            })
        })
    }
    
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    func onSearchResult(interfaceId: String, callbackFn: String, error: String?, le: [String : String]) {
        if (error != nil) {
            sendBtError(interfaceId: interfaceId, interfaceFunc: callbackFn, error: error ?? "unknown error");
        } else {
            var deviceList: [[String: String]] = []
            for (address, deviceName) in le {
                var deviceInfo: [String: String] = [:]
                deviceInfo["Address"] = address
                deviceInfo["Name"] = deviceName
                deviceList.append(deviceInfo)
            }
            
            var deviceListString = "["

            for (index, (address, deviceName)) in le.enumerated() {
                // Create JSON object string manually, assuming `address` and `deviceName` are safe strings.
                let deviceInfoString = """
                {
                    "Address": "\(address)",
                    "Name": "\(deviceName)"
                }
                """
                
                deviceListString += deviceInfoString
                
                // Add a comma unless it's the last element
                if index < le.count - 1 {
                    deviceListString += ","
                }
            }

            deviceListString += "]"
            webView.evaluateJavaScript("\(callbackFn)('\(interfaceId)', null, \(deviceListString))")
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: deviceList, options: .prettyPrinted)
//                if let jsonString = String(data: jsonData, encoding: .utf8) {
//                    webView.evaluateJavaScript("\(callbackFn)('\(interfaceId)', null, '\(jsonString)')")
//                }
//            } catch {
//                print("Failed to serialize JSON: \(error.localizedDescription)")
//                webView.evaluateJavaScript("\(callbackFn)('\(interfaceId)', '\(error.localizedDescription)')")
//            }
        }
    }
    
    func onResult(interfaceId: String, callbackFn: String, error: String?) {
        if (error != nil) {
            sendBtError(interfaceId: interfaceId, interfaceFunc: callbackFn, error: error ?? "unknown error");
        } else {
            webView.evaluateJavaScript("\(callbackFn)('\(interfaceId)', null, true)")
        }
    }
    
    func onMessage(interfaceId: String, callbackFn: String, data: String, uuid: String) {
        let replacements: [String: String] = [
            "\\": "\\\\", // Escape backslash
            "'": "\\'",   // Escape single quote
            "\"": "\\\"", // Escape double quote (if needed)
            "\r": "\\r",  // Escape carriage return
            "\n": "\\n",  // Escape new line
            "\t": "\\t",  // Escape tab
            "/": "\\/"    // Escape forward slash (for regex use cases)
        ]
        var escapedData = data;
        
        // Apply all replacements
        for (target, replacement) in replacements {
            escapedData = escapedData.replacingOccurrences(of: target, with: replacement)
        }
        //webView.loadUrl("javascript: " + callbackFn + "('"+ interfaceId + "', '"+ data + (uuid == null ? "')" : "', '" + uuid + "')"));
        //let escapedData = data.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("\(callbackFn)('\(interfaceId)', '\(escapedData)', '\(uuid)')")
    }
    
    func sendBtError(interfaceId: String, interfaceFunc: String, error: String) {
        let escapedError = error.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("\(interfaceFunc)('\(interfaceId)', {'succeed' : false, 'message': '\(escapedError)'})")
    }
    //END nfc, bt code
    
    //MenuView with size constraints
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuLeadingContraint: NSLayoutConstraint!
    @IBOutlet weak var menuWidthConstraint: NSLayoutConstraint!
    
    //MenuView's subviews
    @IBOutlet weak var CompanityMenu: UIView!
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet var mainContainerView: UIView!
    @IBOutlet weak var tappableView: UIView!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var companityView: UIView!
    @IBOutlet weak var attendenceView: UIView!
    @IBOutlet weak var boardView: UIView!
    @IBOutlet weak var contactView: UIView!
    
    @IBOutlet weak var logOutBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var swipeView: UIView!
    
    //For MODULE MENU
    @IBOutlet weak var moduleMenuCollectionView: UICollectionView!
    @IBOutlet weak var moduleMenuCVFlowLayout: UICollectionViewFlowLayout!
    //@IBOutlet weak var webView: WKWebView!
    var webView: WKWebView!
    @IBOutlet weak var webMenu: WKWebView!
    
    var reloadBtn: UIButton!
    var indicator: UIActivityIndicatorView!
    
    var selectedModule = Module.companity
    
    var menuModuleData: [MenuModule] = []
    var cookieData: [String : String]?
    var appID: String?
    var indexURL: String?
    
    var sideSize: CGFloat!
    var cellSpacing: CGFloat = 0.0
    var numberOfCellsToDisplayHorizontally = 0
    var isMenuLocked = true;
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var statusBarDelegate: UIView!
    //@IBOutlet weak var StatusBarHeight: NSLayoutConstraint!
    @IBOutlet weak var menuStatusBarHeight: NSLayoutConstraint!
    @IBOutlet weak var loadingDot: UIImageView!
    //@IBOutlet weak var menuViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var deptNameLabel: UILabel!
    @IBOutlet weak var companyNameLabel: UILabel!
    var scenarioLoadTimer:Timer?
    
    var _base: BaseFormClass?
    var cookies: [HTTPCookie] = [];
    //nfc, bt code
    var bluetoothHelperMap: [String : BluetoothHelper] = [:]
    var session: NFCNDEFReaderSession?
    var nfcCallbackFn: String?
    var customActionDelegate: CustomActionDelegate?
    var customAuthDelegate: CustomAuthDelegate?
    var erpAuthToken: String?
    var erpAppID: String?
    var flexAppID: String?
    var linkParam: String?
    var pendingCompletion: (([URL]?) -> Void)?
    var limitsNavigationsToAppBoundDomains: Bool?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        print("LATEST for 0.3.3")
        //StatusBarHeight.constant = STATUSBAR_HEIGHT
        menuStatusBarHeight.constant = STATUSBAR_HEIGHT
        //menuViewTopConstraint.constant = -STATUSBAR_HEIGHT
        //Do any additional setup after loading the view.
        menuView.layer.shadowColor = UIColor.gray.cgColor
        menuView.layer.shadowOpacity = 0.5
        menuView.layer.shadowOffset = CGSize(width: 2.0, height: 0.0)

        CompanityMenu.layer.shadowColor = UIColor.gray.cgColor
        CompanityMenu.layer.shadowOpacity = 0.5
        CompanityMenu.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        companityView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(moduleSelected(_:))))
        attendenceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(moduleSelected(_:))))
        boardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(moduleSelected(_:))))
        contactView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(moduleSelected(_:))))
        
        companityView.tag = Module.companity.rawValue
        attendenceView.tag = Module.attendence.rawValue
        boardView.tag = Module.board.rawValue
        contactView.tag = Module.contact.rawValue

        (companityView.viewWithTag(1) as? UIButton)?.aligTextCenterX()
        (attendenceView.viewWithTag(1) as? UIButton)?.aligTextCenterX()
        (boardView.viewWithTag(1) as? UIButton)?.aligTextCenterX()
        (contactView.viewWithTag(1) as? UIButton)?.aligTextCenterX()
        closeBtn.aligTextCenterX()

        
        
        //Module Menu CV initialization
        numberOfCellsToDisplayHorizontally = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? 4 : 2
        moduleMenuCollectionView.allowsMultipleSelection = false
        moduleMenuCollectionView.register(UINib(nibName: "ModuleMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ModuleMenuCollectionViewCell")
        let verticalInset = floor(moduleMenuCollectionView.frame.width*0.06 + profileImage.frame.height/2)
        let horzInset = floor(moduleMenuCollectionView.frame.width * 0.07)
        moduleMenuCollectionView.contentInset = UIEdgeInsets(top: verticalInset, left: horzInset, bottom: verticalInset, right: horzInset)
        moduleMenuCVFlowLayout.minimumLineSpacing = cellSpacing
        moduleMenuCVFlowLayout.minimumInteritemSpacing = cellSpacing
        moduleMenuCollectionView.delegate = self
        moduleMenuCollectionView.dataSource = self
        
        let tappableTapGesture = UITapGestureRecognizer(target: self, action: #selector(masterTappableTapped(_:)))
        tappableTapGesture.delegate = self
        tappableView.addGestureRecognizer(tappableTapGesture)
        
//        let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handleDummyViewPan(_:)))
//        swipeView.addGestureRecognizer(panGestureRec)
//        view.bringSubviewToFront(swipeView)
        let webConfiguration = WKWebViewConfiguration()
        if let limit = limitsNavigationsToAppBoundDomains {
            webConfiguration.limitsNavigationsToAppBoundDomains = limit;
        }
        webConfiguration.processPool = WKProcessPool();
        let webPreference = WKPreferences()
        webPreference.javaScriptEnabled = true
        webConfiguration.preferences = webPreference
        webConfiguration.setURLSchemeHandler(AssetsSchemeHandler(), forURLScheme: "assets")
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        mainContainerView.insertSubview(webView, at: 1)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isHidden = false
        // Add edge swipe gesture recognizer
        let edgeSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        edgeSwipeGesture.edges = .left // Detect left edge swipes
        edgeSwipeGesture.delegate = self
        webView.addGestureRecognizer(edgeSwipeGesture)
        
        #if !RELEASE
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        
        let wvTopConstraint = NSLayoutConstraint(item: webView!, attribute: .top, relatedBy: .equal, toItem: detailContainerView, attribute: .top, multiplier: 1, constant: 0)
        let wvBottomConstraint = NSLayoutConstraint(item: webView!, attribute: .bottom, relatedBy: .equal, toItem: detailContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        let wvLeadingConstraint = NSLayoutConstraint(item: webView!, attribute: .leading, relatedBy: .equal, toItem: detailContainerView, attribute: .leading, multiplier: 1, constant: 0)
        let wvTrailingConstraint = NSLayoutConstraint(item: webView!, attribute: .trailing, relatedBy: .equal, toItem: detailContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        let wvHeightConstraint = NSLayoutConstraint(item: webView!, attribute: .height, relatedBy: .equal, toItem: detailContainerView, attribute: .height, multiplier: 1, constant: 0)
        let wvWidthConstraint = NSLayoutConstraint(item: webView!, attribute: .width, relatedBy: .equal, toItem: detailContainerView, attribute: .width, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([wvTopConstraint, wvBottomConstraint, wvLeadingConstraint, wvTrailingConstraint, wvHeightConstraint, wvWidthConstraint])
        
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.uiDelegate = self
        let blockRules  = """
     [{
           "trigger": {
               "url-filter": "assets://.*",
               "if-domain": ["app.flextudio.com"],
               "load-context": ["child-frame"],
               "resource-type": ["document", "svg-document", "image"],
               "load-type": ["third-party"]
           },
           "action": {
               "type": "make-https"
           }
       }]
  """
        WKContentRuleListStore.default().compileContentRuleList(
          forIdentifier: "MWWKWebViewContentRules", // ContentBlockingRules
          encodedContentRuleList: blockRules) {(contentRuleList, error) in
              if let error = error {
                  error.localizedDescription
                  return
              }
              self.webView.configuration.userContentController.add(contentRuleList!)
          }
        //WKUserContentController를 사용하여 웹뷰에서 스크립트로 네이티브 함수를 호출 가능하도록 함
        //사용 예시
        //window.webkit.messageHandlers.MobileTest.postMessage('gps')
        if let cookie = cookieData {
            for (name, value) in cookie {
                let httpCookie = HTTPCookie(properties: [
                    .domain: ".flextudio.com",
                    .path: "/",
                    .name: name,
                    .value: value,
                    .secure: "TRUE"
                ])!
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(httpCookie) {
                    self.cookies.append(httpCookie);
                }
            }
        }
        //let cookie = HTTPCookieStorage.shared.cookies
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "MobileTest")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnResultByCallJS(_:)), name: NSNotification.Name(rawValue: "locationUpdated"), object: nil)
        
        setupReloadBtn()
        setUpSpinner()
        
        //https://zeddios.tistory.com/372
        //let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        NotificationCenter.default.addObserver(self,selector: #selector(notiDidReceive), name: NSNotification.Name(rawValue: NotiConstants.notificationpayload), object: nil)
        let notificationPayload = NotiConstants.sharedInstance.userDefaults.object(forKey: NotiConstants.notificationpayload) as? NSDictionary
        NotiConstants.sharedInstance.userDefaults.removeObject(forKey: NotiConstants.notificationpayload)
        if !loadWebvviewUrl(notificationPayload as? [AnyHashable : Any]) {
            var urlString = "https://\((flexAppID.map { "\($0).app" }) ?? "app").flextudio.com/"
            if let qs = linkParam {
                urlString += "?\(qs)"
            }
            if let url = URL(string: urlString) {
                let myRequest = URLRequest(url: url)
                webView.load(myRequest)
            }
        }
        
        //loadMenuModules()
        
        /*if let myURL = URL(string: "http://flextudio-proto.azurewebsites.net/menu") {
            let myRequest = URLRequest(url: myURL)
            webMenu.load(myRequest)
        }
        webMenu.scrollView.bounces = false
        webMenu.scrollView.bouncesZoom = false
        webMenu.uiDelegate = self
        webMenu.navigationDelegate = self
        let contentController2 = self.webMenu.configuration.userContentController
        contentController2.add(self, name: "MobileTest")*/
        moduleMenuCollectionView.reloadData()
       /* if  indexURL != nil {
            selectedModule = .none
            children.first?.willMove(toParent: nil)
            children.first?.view.removeFromSuperview()
            children.first?.removeFromParent()
            detailContainerView.subviews.forEach({ $0.removeFromSuperview() })
            detailContainerView.isHidden = true
            webView.isHidden = false
            statusBarDelegate.isHidden = false
            if let myURL = URL(string: indexURL!) {
                let myRequest = URLRequest(url: myURL)
                webView.load(myRequest)
            }*/
            companityView.isHidden = true
            attendenceView.isHidden = true
            boardView.isHidden = true
        /*} else {
            openCompanity()
        }*/
        getLoginBaseForm()
        userNameLabel.text = _base?.getEmpName()
        deptNameLabel.text = _base?.getDeptName()
        companyNameLabel.text = _base?.getCompanyName()
        profileImage.layer.borderColor = UIColor.white.cgColor
        profileImage.layer.borderWidth = 2
        profileImage.layer.cornerRadius = 6
        profileImage.clipsToBounds = true
        //profileImage.sd_setImage(with: MainMasterDetailVC.getUserProfileImageURL(empSeq: String(BaseUserValue.EmpSeq)), placeholderImage:  #imageLiteral(resourceName: "test_icon_profile"), completed: nil)
        
//        if let imgUrl = Bundle.main.url(forResource: "loading-dot", withExtension: "gif"){
//            var imageData = Foundation.Data()
//            // Data object to fetch image data
//            do {
//                imageData = try Foundation.Data(contentsOf: imgUrl)
//                print(imageData)
//            } catch {
//                print("error")
//            }
//            
//            if let gifImage = UIImage.sd_image(withGIFData: imageData) {
//                loadingDot.animationImages = gifImage.images
//                loadingDot.animationDuration = gifImage.duration
//                loadingDot.animationRepeatCount = 0
//                loadingDot.image = gifImage.images?.last
//            }
//        }
        //TokenHandler().saveTokenToDB()
        
        addKeyboardNotification()
    }
    var startLocation: CGPoint?
    @objc func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let totalWidth = view.bounds.size.width
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            startLocation = location
            print("Swipe began at: \(location)")
            webView.evaluateJavaScript("onSwipeBegin();") { (result, error) in
                if let err = error {
                    print("Error biginSwipe: \(err.localizedDescription)")
                }
            }
        case .changed:
            let startX = startLocation?.x
            let locationX = location.x
            let swipeDistance = locationX - (startX ?? 0)
            let percent = swipeDistance * 100.0 / totalWidth
            webView.evaluateJavaScript("setSwipeTranslate(\(percent));"){ (result, error) in
                if let error = error {
                    print("Error translateX: \(error.localizedDescription)")
                }
            }
        case .ended:
            guard let start = startLocation else { return }
            
            let swipeDistance = location.x - start.x
            print("Swipe distance: \(swipeDistance)")
            
            let percent = swipeDistance * 100.0 / totalWidth
            webView.evaluateJavaScript("onSwipeEnded(\(percent));") { (result, error) in
                if let error = error {
                    print("Error executing JavaScript: \(error.localizedDescription)")
                } else {
                    print("Back navigation triggered successfully.")
                }
            }
        case .cancelled:
            print("Swipe cancelled at: \(location)")
            webView.evaluateJavaScript("onSwipeEnded();")
        case .failed:
            print("Swipe failed at: \(location)")
            webView.evaluateJavaScript("onSwipeEnded();")
        default:
            break
        }
    }

    fileprivate func loadWebvviewUrl(_ notificationPayload: [AnyHashable : Any]?) -> Bool {
        if let actionJson = notificationPayload?[NotiConstants.actionJson], let actionBody = actionJson as? String, let action = try? JSONSerialization.jsonObject(with: actionBody.data(using: .utf8)!, options: []) as? [String:String] {
            if let linkParm = action["linkParam"] {
                if let url = URL(string: "https://app.flextudio.com/?\(linkParm)") {
                    webView.load(URLRequest(url: url))
                    return true
                }
            }
        }
        return false
    }
    
    @objc func notiDidReceive(notification: NSNotification){
        DispatchQueue.main.async {
            let notificationPayload = notification.userInfo;
            self.loadWebvviewUrl(notificationPayload)
        }
    }
    
    func getLoginBaseForm(){
        if _base == nil {
            _base = BaseFormClass()
            let paths = NSString(string: (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] ))
            let devicePath = paths.appendingPathComponent("BaseFormClass.txt")
            let checkValidation = FileManager.default
            if checkValidation.fileExists(atPath: devicePath) {
                let fileContent1: Foundation.Data? = checkValidation.contents(atPath: devicePath)
                let str = NSString(data: fileContent1!, encoding: String.Encoding.utf8.rawValue)!
                _base =  Mapper().map(JSONString: str as String)
            }
        }
    }
    
    func setUpSpinner() {
        indicator = UIActivityIndicatorView(style: .medium)
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);

        menuView.addSubview(indicator)
        menuView.bringSubviewToFront(indicator)
        indicator?.isHidden = true
    }
    
    func spinSpinner() {
        DispatchQueue.main.async { [unowned self] in
            self.indicator?.isHidden = false
            self.indicator?.startAnimating()
        }
    }
    
    func stopSpinner() {
        DispatchQueue.main.async { [unowned self] in
            self.indicator?.isHidden = true
            self.indicator?.stopAnimating()
        }
    }
    
    func setupReloadBtn() {
        reloadBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        //reloadBtn.setImage(UIImage(named: "perm_group_sync_settings"), for: .normal)
        reloadBtn.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        reloadBtn.layer.cornerRadius = reloadBtn.frame.width/2
        reloadBtn.layer.masksToBounds = true
        reloadBtn.isHidden = true
        reloadBtn.addTarget(self, action: #selector(reloadMenuModules), for: UIControl.Event.touchUpInside)

        menuView.addSubview(reloadBtn!)
        menuView.bringSubviewToFront(reloadBtn!)
    }
    
    @objc func masterTappableTapped(_ sender: UITapGestureRecognizer){
        closeMenuDrawer()
    }

    @objc func handleDummyViewPan(_ recognizer: UIPanGestureRecognizer) {
        if !isMenuLocked {
        view.endEditing(true)
        let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
        let translation = recognizer.translation(in: view)
        
        switch recognizer.state {
        case .began:
            break
            
        case .changed:
            if translation.x >= 0 && menuLeadingContraint.constant + translation.x >= 0 {
                menuLeadingContraint.constant = 0
                tappableView.isHidden = false
            } else if translation.x <= 0 && menuLeadingContraint.constant + translation.x <= -menuWidthConstraint.constant {
                menuLeadingContraint.constant = -menuWidthConstraint.constant
                tappableView.isHidden = true
            } else {
                menuLeadingContraint.constant += translation.x
            }
            
            DispatchQueue.main.async { [unowned self] in
                self.menuView.superview?.layoutIfNeeded()
            }
            break
            
        case .ended:
            if gestureIsDraggingFromLeftToRight {
                if menuLeadingContraint.constant >= 0 {
                    //Do nothing
                } else {
                    openMenuDrawer()
                }
            } else {
                if menuLeadingContraint.constant <= -menuWidthConstraint.constant {
                    //Do nothing
                } else {
                    closeMenuDrawer()
                }
            }
            break
            
        default:
            break
        }
        
        recognizer.setTranslation(CGPoint.zero, in: view)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(enterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        //Set MenuView size according to device type
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            menuWidthConstraint.constant = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)// * 0.85
            
        case .pad:
            menuWidthConstraint.constant = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)// * 0.85
            
        case .unspecified:
            // Uh, oh! What could it be?
            break
            
        default:
            break
        }
        
        reloadBtn.center = CGPoint(x: menuWidthConstraint.constant/2, y: menuView.frame.height/2)
        indicator.center = CGPoint(x: menuWidthConstraint.constant/2, y: menuView.frame.height/2)
        
        if isMenuLocked {
            menuLeadingContraint.constant = 0
            tappableView.isHidden = true
            closeBtn.isHidden = true
        } else {
            menuLeadingContraint.constant = -menuWidthConstraint.constant
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidLayoutSubviews() {
        //MODULES MENU Layout Re-render
        DispatchQueue.main.async { [unowned self] in
            self.moduleMenuCollectionView.superview?.layoutIfNeeded()
            self.moduleMenuCollectionView.reloadData()
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }

    @objc func rotated() {
        //menuViewTopConstraint.constant = -UIApplication.shared.statusBarFrame.size.height
//        if let mainNC = children.first as? UINavigationController, let mainVC = mainNC.viewControllers.first as? MainViewController {
//            if mainVC.actionButton?.active ?? false {
//                mainVC.actionButton?.toggleMenu()
//            }
//        }
    }
    @objc func enterForeground() {
        webView.evaluateJavaScript("onForeground();")
    }
    @objc func enterBackground() {
        webView.evaluateJavaScript("onBackground();")
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        if !isMenuLocked {
            closeMenuDrawer()
        }
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        let alert = UIAlertController(title: StringConstants.LogoutConfirmMsg, message: nil, preferredStyle: UIAlertController.Style.alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("NO", comment: "아니오"), style: UIAlertAction.Style.cancel, handler: nil)
        alert.addAction(cancelAction)
        let okAction = UIAlertAction(title: NSLocalizedString("YES", comment: "네"), style: UIAlertAction.Style.default, handler: {(action: UIAlertAction!) in
            self.executeLogout()
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func executeLogout(){
        if let sessionInfo = Util.readFromFile("sessionInfo"), !sessionInfo.isEmpty {
            if let sessionObject = try? JSONSerialization.jsonObject(with: sessionInfo.data(using: .utf8)!, options: []) as? [String:Any] {
                let awsService = AwsApiService()
                class delegate: AwsApiResult {
                    weak var parent: MainMasterDetailVC?
                    init(parent: MainMasterDetailVC) {
                        self.parent = parent;
                    }
                    
                    func onAwsResult(result: [String:Any]?) {
                        if let resultMap = result {
                            if let errorMsg = resultMap["error"] as? String {
                                parent?.view.showToast(message: errorMsg)
                            } else {
                                parent?.clearSessionData()
                            }
                        } else {
                            parent?.view.showToast(message: "Unsuccessful")
                        }
                    }
                }
                awsService.delegate = delegate(parent: self)
                var requestObject: [String: Any] = [:]
                requestObject["baseCompanyId"] = sessionObject["baseCompanyID"] as! String
                requestObject["baseUserId"] = sessionObject["baseUserID"] as! String
                requestObject["sessionId"] = sessionObject["sessionID"] as! String
                awsService.callAwsApi(path: "logOut", requestJson: requestObject)
            }
        }
    }
    
    fileprivate func clearSessionData() {
        SharedPreferenceUtil.remove(Const.DEVICE_TOKEN)
        SharedPreferenceUtil.remove(CommonConstants.USER_INFO_LASTDATETIME)
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        //TokenHandler().removeToken(isFromUserLogout: true)
        
        let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if let fileURL = dir?.appendingPathComponent( "sessionInfo").appendingPathExtension("txt") {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch let error as NSError {
                print("Error: \(error.domain)")
            }
        }
        
        //MARK: TO-DO
        /*
         let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = mainStoryboard.instantiateViewController(withIdentifier: "MainNC") as! UINavigationController
        navigationVC.setNavigationBarHidden(true, animated: false)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "emplvc") as! LoginViewController
        
        UIApplication.shared.keyWindow?.rootViewController = navigationVC
        navigationVC.pushViewController(vc, animated: false)
        */
    }
    
    //MARK: METHODS - ADD OR REMOVE CHILD VIEW CONTROLLER INTO OR FROM CONTAINER VIEW.
    func add(childNavigationController navController: UINavigationController) {
        // Add Child View Controller
        addChild(navController)
        
        // Configure Child View
        navController.view.frame = detailContainerView.bounds
        navController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add Child Navigation View as Subview
        detailContainerView.addSubview(navController.view)
        
        // Notify Child Navigation View Controller
        navController.didMove(toParent: self)
    }
    
    func add(childViewController viewController: UIViewController) {
        // Add Child View Controller
        addChild(viewController)

        // Add Child View as Subview
        detailContainerView.addSubview(viewController.view)

        // Configure Child View
        viewController.view.frame = detailContainerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Notify Child View Controller
        viewController.didMove(toParent: self)
    }
    
    func remove(childViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParent()
    }
    
    //MARK: Retrieving Pinned Data
//    func loadMenuModules(){
//        let csv = CommonSvcCaller(scr: self)
//        var paramArr: [String] = []
//        paramArr.append(String(BaseUserValue.EmpSeq))
//        csv.QueryExecuteCustomSPCall(spName: CommonConstants._SCAMobileQueryDemoMenu, params: paramArr, isBis: true)
//
//        spinSpinner()
//    }
    
    @objc func reloadMenuModules() {
        reloadBtn.isHidden = true
        //loadMenuModules()
    }

    @objc func moduleSelected(_ sender: UITapGestureRecognizer) {
        detailContainerView.isHidden = false
        webView.isHidden = true
        statusBarDelegate.isHidden = true
        
        //Clear contents and stop loading WKWebView
        if let clearURL = URL(string: "about:blank") {
            webView.load(URLRequest(url: clearURL))
        }
        webView.stopLoading()
        sender.view?.viewWithTag(2)?.isHidden = true
       
        //Remove the older module's child viewcontroller
        if sender.view!.tag != selectedModule.rawValue {
            //Notify MainVC that it's being removed so that it can remove observers, gestures and cyclic referencing variables
            if selectedModule == .companity {
                //((children.first as? UINavigationController)?.viewControllers.first as? MainViewController)?.removedFromMasterDetailVC()
            }

            children.first?.willMove(toParent: nil)
            children.first?.view.removeFromSuperview()
            children.first?.removeFromParent()
            detailContainerView.subviews.forEach({ $0.removeFromSuperview() })
        }
        
        switch sender.view {
        case companityView:
            if selectedModule != .companity {
                selectedModule = .companity
                
                //Load Companity's new instance
                //openCompanity()
            }
            break
            
        case attendenceView:
            if selectedModule != .attendence {
                selectedModule = .attendence
                
                //Load Attendence's new instance
                openAttendence()
            }
            break
            
        case boardView:
            if selectedModule != .board {
                selectedModule = .board
                
                //Load Board's new instance
                //openBoard()
            }
            break
            
        case contactView:
            if selectedModule != .contact {
                selectedModule = .contact
                
                //Load Contact's new instance
                //openOrganizationChart()
            }
            break
            
        default:
            break
        }
        
        closeMenuDrawer()
    }
    
    fileprivate func clearPreviousload() {
        //Remove previously loaded modules
        selectedModule = .none
        children.first?.willMove(toParent: nil)
        children.first?.view.removeFromSuperview()
        children.first?.removeFromParent()
        detailContainerView.subviews.forEach({ $0.removeFromSuperview() })
        
        detailContainerView.isHidden = true
        webView.isHidden = false
        statusBarDelegate.isHidden = false
        
        //Clear contents before loading WKWebView with new URL
        if !(webView.url?.absoluteString ?? "").isEmpty {
            if let clearURL = URL(string: "about:blank") {
                webView.load(URLRequest(url: clearURL))
            }
        }
    }
    
    func webViewModuleTapped(index: Int) {
        clearPreviousload()
        if let linkUrl = menuModuleData[index].link {
        //Loading the new link
        if let myURL = URL(string: linkUrl) {
        //if let myURL = URL(string: "https://scenario.flextudio.com/public/run.html?ScenarioId="+scenarioid+"&sessionID="+BaseUserValue.SESSION_ID+"&appId="+appID!) {
            scenarioLoadTimer?.invalidate()
            scenarioLoadTimer = nil
            var myRequest = URLRequest(url: myURL)
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (name, value) in headers {
                myRequest.addValue(value, forHTTPHeaderField: name)
            }
            webView.load(myRequest)
        }
        }

        closeMenuDrawer()
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
        loadingView.isHidden = false
//        loadingDot.startAnimating()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //startTimer()
        removeWebViewLoading()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showFailMessage()
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if(error._code == NSURLErrorNotConnectedToInternet || error._code == NSURLErrorNetworkConnectionLost) {
            let assetPath = NWPathMonitor().currentPath.usesInterfaceType(.wifi) ? "assets://app.flextudio.com/msgWifi.html" : "assets://app.flextudio.com/msgLTE.html"
            if let schemeURL = URL(string: assetPath) {
                webView.load(URLRequest(url: schemeURL))
            }
        }
    }
    
    func removeWebViewLoading() {
        loadingView.isHidden = true
//        loadingDot.stopAnimating()
        scenarioLoadTimer?.invalidate()
        scenarioLoadTimer = nil
    }
    
    func webStatusBarColor(_ hexString: String, isDarkBackground:Bool) {
        var chars = Array(hexString.hasPrefix("#") ? hexString.dropFirst() : hexString[...])
        let red, green, blue, alpha: CGFloat
        switch chars.count {
        case 3:
            chars = chars.flatMap { [$0, $0] }
            fallthrough
        case 6:
            chars = ["F","F"] + chars
            fallthrough
        case 8:
            alpha = CGFloat(strtoul(String(chars[0...1]), nil, 16)) / 255
            red   = CGFloat(strtoul(String(chars[2...3]), nil, 16)) / 255
            green = CGFloat(strtoul(String(chars[4...5]), nil, 16)) / 255
            blue  = CGFloat(strtoul(String(chars[6...7]), nil, 16)) / 255
        default:
            return
        }
        statusBarDelegate.backgroundColor = UIColor.init(red: red, green: green, blue: blue, alpha: alpha)
        isDarkContentBackground = isDarkBackground
        setNeedsStatusBarAppearanceUpdate()
    }
    var isDarkContentBackground = false
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if isDarkContentBackground { // <5>
            return .lightContent
        } else {
            return .darkContent
        }
    }
    func getWiFiAddress() -> String? {
        var address : String?

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
    func resetModulesUI() {
        companityView.backgroundColor = UIColor.white
        attendenceView.backgroundColor = UIColor.white
        boardView.backgroundColor = UIColor.white
        contactView.backgroundColor = UIColor.white
        
        companityView.viewWithTag(2)?.isHidden = true
        attendenceView.viewWithTag(2)?.isHidden = true
        boardView.viewWithTag(2)?.isHidden = true
        contactView.viewWithTag(2)?.isHidden = true
    }
    
//    func openCompanity(){
//        //Load Storyboard and Instantiate View Controller for Companity
//        let navController = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "MainNC") as! UINavigationController
//        if let mainVC = navController.topViewController as? MainViewController {
//            mainVC.parentContainerView = detailContainerView
//            mainVC.tappableView = tappableView
//            mainVC.delegate = self
//
//            //Add Navigation Controller as Child View Controller
//            add(childNavigationController: navController)
//        }
//    }
//
//    func openBoard(){
//        //Load Storyboard and Instantiate View Controller for Companity
//        let boardVC = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "BoardViewController") as! BoardViewController
//        boardVC.delegate = self
//        add(childViewController: boardVC)
//    }
//
//    func openOrganizationChart(){
//        //Load Storyboard and Instantiate View Controller for OrganizationChart
//        let orgVC = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "OrganizationalVC") as! OrganizationalVC
//        orgVC.delegate = self
//        add(childViewController: orgVC)
//        orgVC.menuBtn.isHidden = false
//        orgVC.backBtn.isHidden = true
//        detailContainerView.layoutIfNeeded()
//    }
    
    func openAttendence(){
        //Load Storyboard and Instantiate View Controller for Attendence
    }
    
    @objc func dummyViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
        closeMenuDrawer()
    }
    
    @objc func dummyViewSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        self.view.endEditing(true)
        
        switch gestureRecognizer.direction {
        case UISwipeGestureRecognizer.Direction.right:
            openMenuDrawer()
            
        case UISwipeGestureRecognizer.Direction.left:
            closeMenuDrawer()
            
        default:
            break
        }
    }
    
    func openMenuDrawer(){
        DispatchQueue.main.async { [unowned self] in
            self.menuLeadingContraint.constant = 0
            UIView.animate(withDuration: 0.2, animations: {[unowned self] in
                self.view.layoutIfNeeded()
                self.tappableView.isHidden = false
                }, completion: nil)
        }
    }
    
    func closeMenuDrawer(){
        DispatchQueue.main.async { [unowned self] in
            self.menuLeadingContraint.constant = -self.menuWidthConstraint.constant
            UIView.animate(withDuration: 0.2, animations: {[unowned self] in
                self.view.layoutIfNeeded()
                self.tappableView.isHidden = true
                }, completion: {[unowned self] (finished: Bool) in
                    if self.isMenuLocked {
                        self.isMenuLocked = false
                        self.closeBtn.isHidden = false
                        self.menuWidthConstraint.constant *= 0.94
                        self.menuLeadingContraint.constant = -self.menuWidthConstraint.constant
                        self.reloadBtn.center = CGPoint(x: self.menuWidthConstraint.constant/2, y: self.menuView.frame.height/2)
                        self.indicator.center = CGPoint(x: self.menuWidthConstraint.constant/2, y: self.menuView.frame.height/2)
                    }
            })
        }
    }
    
    func startTimer() {
        scenarioLoadTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(onTimeUp), userInfo: nil, repeats: true)
    }
    
    @objc func onTimeUp() {
        if !loadingView.isHidden {
            removeWebViewLoading()
            showFailMessage()
        }
    }
    
    func showFailMessage() {
        let msgBox = YlwMessageBox()
        let result = msgBox.showDialog(NSLocalizedString("scanarioLoadFailed", comment: "Failed to load scenario"), title: "", msgBoxType: "MsgBoxTypeOK", isSyncMode: true)
        if (result == 1) {
            isMenuLocked = true
            menuWidthConstraint.constant = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            reloadBtn.center = CGPoint(x: menuWidthConstraint.constant/2, y: menuView.frame.height/2)
            indicator.center = CGPoint(x: menuWidthConstraint.constant/2, y: menuView.frame.height/2)
            tappableView.isHidden = true
            closeBtn.isHidden = true
            DispatchQueue.main.async { [unowned self] in
                self.menuLeadingContraint.constant = 0
                UIView.animate(withDuration: 0.2, animations: {[unowned self] in
                    self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    func addKeyboardNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }
    @objc func keyboardWillHide(){
        webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    fileprivate func getDownloadDelegate(_ function: String) -> DownloadDelegate {
        return {
            class Delegate : DownloadDelegate {
                let function: String
                let webView: WKWebView
                init(_ function: String, webView: WKWebView){
                    self.function = function
                    self.webView = webView
                }
                func downloadEnd(isSuceed: Bool, message: String?) {
                    DispatchQueue.main.async { [unowned self] in
                        let js = "\(function)(\(isSuceed), '\(message ?? "")')"
                        webView.evaluateJavaScript(js)
                    }
                }
            }
            return Delegate(function, webView: webView)
        }()
    }

    /////for gps
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message)
        if let info = message.body as? String {
            if let messageObject = try? JSONSerialization.jsonObject(with: info.data(using: .utf8)!, options: []) as? [String:Any] {
                let param = messageObject["param"] as? [String:Any]
                let callback = messageObject["callback"] as? [String:Any]
                let id = (messageObject["id"] as? String) ?? ""
                if let action = messageObject["action"] as? String {
                    switch action {
                    case "openmenu":
                        openMenuDrawer()
                    case "statusbar":
                        if let color = param?["color"] as? String {
                            let systemColor = (param?["systemColor"] as? String) ?? ""
                            let isDarkBackground = (systemColor == "white")
                            webStatusBarColor(color,isDarkBackground: isDarkBackground)
                        }
                    case "initdata":
                        if let initData = Util.readFromFile("userInfo"), let function = callback?["function"] as? String {
                            //todo
                            let js = function + "(" + initData + ")"
                            self.webView.evaluateJavaScript(js)
                        }
                    case "loadgps":
                        //systemCallback need id
                        let systemCallback = (callback?["function"] as? String) ?? ""
                        let module = GPSModule(id:id,systemCallback:systemCallback,param:param)
                        module.start()
                    case "loadgpsnavigation":
                        let systemCallback = (callback?["function"] as? String) ?? ""
                        let module = GPSModule(id:id,systemCallback:systemCallback,param:param, isAccurate: true)
                        module.start()
                    case "loadbarcode":
                        let systemCallback = (callback?["function"] as? String) ?? ""
                        let afterEventName = (param?["afterEventName"] as? String) ?? ""
                        let isMulti : Bool
                        if !afterEventName.isEmpty, let afterEventObject = try? JSONSerialization.jsonObject(with: afterEventName.data(using: .utf8)!, options: []) as? [String:Any] {
                            isMulti = afterEventObject["ismulti"] as? Bool ?? false
                        } else {
                            isMulti = false
                        }
                        let onScannerResult: (Bool, String?, String?) -> Void = { success, code, message in
                            if success {
                                let script =  "\(systemCallback)('\(id)',{'status':{'succeed' : true},'data':'\(code ?? "")', 'afterEventName':'\(afterEventName)'});"
                                self.webView.evaluateJavaScript(script)
                            } else {
                                let script = "\(systemCallback)('\(id)',{'status':{'succeed' : false,'message':'\(message ?? NSLocalizedString("ScannerDismissed", comment: "Scanner was dismissed"))'},'data':{'afterEventName':'\(afterEventName)'}});"
                                self.webView.evaluateJavaScript(script)
                            }
                        }
                        func onCameraPermission(_ granted: Bool) {
                            if granted {
                                DispatchQueue.main.async {
                                    let scannerVC = CameraViewController()
                                    scannerVC.onScannerResult = onScannerResult
                                    scannerVC.isMulti = isMulti
                                    scannerVC.modalPresentationStyle = .overFullScreen
                                    self.present(scannerVC, animated: true, completion: nil)
                                }

                            } else {
                                onScannerResult(false, nil, NSLocalizedString("RequestCameraPermission", comment: "You need access permission for the camera"))
                            }
                        }
                        switch AVCaptureDevice.authorizationStatus(for: .video) {
                            case .authorized:
                                onCameraPermission(true)
                            case .notDetermined:
                                AVCaptureDevice.requestAccess(for: .video) { granted in
                                    onCameraPermission(granted)
                                }
                            case .denied, .restricted:
                                onCameraPermission(false)
                            @unknown default:
                                onCameraPermission(false)
                        }
                    case "loadbeacon":
                        //systemCallback need id
                        //let systemCallback = (callback?["function"] as? String) ?? ""
                        //let time = (param?["time"] as? String) ?? ""
                        //lcModule = BeaconModule(systemCallback:systemCallback,param:param, time:time, delegate:self as CLLocationManagerDelegate)
                        //lcModule?.start()
                        break
                    case "filedownload":
                        let systemCallback = (callback?["function"] as? String) ?? ""
                        let serviceURL = param?["serviceURL"] as? String
                        let bis = param?["bis"] as? String
                        let filePath = param?["filePath"] as? String
                        
                        if let serviceURL = serviceURL, let bis = bis, let filePath = filePath {
                            webFileDownload(id: id, serviceURL:serviceURL, bis:bis, filePath: filePath,callback:systemCallback)
                        }
                    case "downloadfiledata":
                        let callback = callback?["function"] as? String
                        if let url = param?["url"] as? String, let xmlns = param?["xmlns"] as? String, let filePath = param?["filePath"] as? String, let token = param?["token"] as? String, let fileName = param?["fileName"] as? String {
                            postFileDataXml(to : url, path: filePath, token: token, xmlns: xmlns, fileName: fileName){ result in
                                if let callback = callback {
                                    switch result {
                                    case .success(let code):
                                        DispatchQueue.main.async {
                                            self.webView.evaluateJavaScript("\(callback)('\(id)', {'status' : {'succeed' : true,'code' : '\(code)'}})")
                                        }
                                    case .failure(let error):
                                        DispatchQueue.main.async {
                                            self.webView.evaluateJavaScript("\(callback)('\(id)', {'status' : {'succeed' : false,'code' : '\(error.message)'}})")
                                        }
                                    }
                                    
                                }
                            }
                        }

                    case "s3down":
                        let partUrls = param?["partUrls"] as? [String]
//                        let partsCount = messageObject["partsCount"] as? Int
                        let partPositions = param?["partPositions"] as? [UInt64]
                        let filename = (param?["filename"] as? String) ?? ""
                        let parallelDownloadCount = param?["parallelDownloadCount"] as? Int
                        if let function = callback?["function"] as? String {
                            let delegate = getDownloadDelegate(function)
                            _ = S3Downloader(downloadUrls :partUrls!, filename: filename, partPositions: partPositions, uivc: self, concurrentCount: parallelDownloadCount, delegate: delegate)
                        }
                    case "s3range":
                        let key = param?["key"] as! String
                        let rangeArr = param?["rangeArr"] as! [String]
                        let filename = (param?["filename"] as? String) ?? ""
                        let partPositions = param?["partPositions"] as? [UInt64]
                        let parallelDownloadCount = param?["parallelDownloadCount"] as? Int
                        if let function = callback?["function"] as? String {
                            let delegate = getDownloadDelegate(function)
                            _ = S3Downloader(key: key, range: rangeArr, filename : filename, partPositions: partPositions, uivc: self, concurrentCount: parallelDownloadCount, delegate: delegate)
                        }
                    case "openscenario":
                        if let url = param?["url"] as? String {
                            clearPreviousload()
                            //Loading the new link
                            if let myURL = URL(string: url) {
                                let myRequest = URLRequest(url: myURL)
                                webView.load(myRequest)
                            }
                            closeMenuDrawer()
                        }
                    case "clearbadge":
                        if let timestamp = param?["timestamp"] as? Int, let unReadCount = param?["unReadCount"] as? Int {
                            UIApplication.shared.applicationIconBadgeNumber = unReadCount
                            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["\(timestamp)"])
                        } else {
                            UIApplication.shared.applicationIconBadgeNumber = 0
                            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                        }
                    case "closeloading":
                        removeWebViewLoading()
                        if let closefunction = callback?["function"] as? String {
                            let js = closefunction + "()"
                            self.webView.evaluateJavaScript(js)
                        }
                    case "logout":
                        let isForced = (param?["isForced"] as? Bool) ?? false
                        if (isForced){
                            executeLogout()
                        }
                        else {
                            logOutTapped(AnyObject.self)
                        }
                    case "nosession":
                        clearSessionData()
                    case "localip":
                        if let wifiFunction = callback?["function"] as? String {
                            let js = wifiFunction + "(" + (getWiFiAddress() ?? "0.0.0.0") + ")"
                            self.webView.evaluateJavaScript(js)
                        }
                    case "loginnotitoken":
                        if let loginFn = callback?["function"] as? String {
                            Installations.installations().installationID { (installationID, error) in
                                if let error = error {
                                    print("Error fetching Firebase installation ID: \(error.localizedDescription)")
                                    let js = loginFn + "('" + (Messaging.messaging().fcmToken ?? "") + "')"
                                    self.webView.evaluateJavaScript(js)
                                    return
                                }
                                guard let installationID = installationID else {
                                    print("Firebase installation ID is nil")
                                    let js = loginFn + "('" + (Messaging.messaging().fcmToken ?? "") + "')"
                                    self.webView.evaluateJavaScript(js)
                                    return
                                }
                                let js = loginFn + "('" + (Messaging.messaging().fcmToken ?? "") + "', '" + installationID + "')"
                                self.webView.evaluateJavaScript(js)
                            }
                        }
                    case "invitedpackageid":
                        if let inviteFn = callback?["function"] as? String {
                            let js = inviteFn + "(true, '" + (Bundle.main.bundleIdentifier ?? "") + "')"
                            self.webView.evaluateJavaScript(js)
                        }
                        break;
                        
                    case "openlinkapp", "OpenLinkApp":
                        if let urlPath = param?["ios"] as? String {
                            let url = URL(string: urlPath)
                            UIApplication.shared.open(url!) { (result) in
                                if result {
                                   // The URL was delivered successfully!
                                    print(result)
                                }
                            }
                        }
                        break;
                    case "getDeviceList":
                        if let function = callback?["function"] as? String, let interfaceId = param?["interface"] as? String {
                            var bluetoothHelper: BluetoothHelper
                            if let existingHelper = bluetoothHelperMap[interfaceId] {
                                bluetoothHelper = existingHelper
                            } else {
                                bluetoothHelper = BluetoothHelper(interfaceId: interfaceId, callbackFn: function, bluetoothResults: self)
                                bluetoothHelperMap[interfaceId] = bluetoothHelper
                            }
                            bluetoothHelper.search(callbackFn: function)
                        }
                        
                        //UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                        /*if let url = URL(string: "App-Prefs:root=Bluetooth") {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }*/
                    case "connectToDevice":
                        if let function = callback?["function"] as? String, let interfaceId = param?["interface"] as? String {
                            if let deviceAddr = param?["address"] as? String {
                                let receiveMessage = param?["receiveMessage"] as! String?
                                var bluetoothHelper: BluetoothHelper
                                if let existingHelper = bluetoothHelperMap[interfaceId] {
                                    bluetoothHelper = existingHelper
                                } else {
                                    bluetoothHelper = BluetoothHelper(interfaceId: interfaceId, callbackFn: function, bluetoothResults: self)
                                    bluetoothHelperMap[interfaceId] = bluetoothHelper
                                }
                                bluetoothHelper.connect(address: deviceAddr, callbackFn: function, receiveMessageFn: receiveMessage)
                            } else {
                                let errMsg = "device address missing";
                                sendBtError(interfaceId: interfaceId, interfaceFunc: function, error: errMsg);
                            }
                        }
                        //turnOnBluetooth()
                    case "sendToDevice":
                        if let function = callback?["function"] as? String, let interfaceId = param?["interface"] as? String {
                            if let bluetoothHelper = bluetoothHelperMap[interfaceId] {
                                if let data = param?["data"] as? String {
                                    bluetoothHelper.send(value: data, callbackFn: function)
                                } else {
                                    sendBtError(interfaceId: interfaceId, interfaceFunc: function, error: "no data param")
                                }
                            } else {
                                sendBtError(interfaceId: interfaceId, interfaceFunc: function, error: "connection hasn't been made")
                            }
                        }
                        
                        //UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    case "disconnectBluetooth":
                        if let function = callback?["function"] as? String, let interfaceId = param?["interface"] as? String {
                            if let bluetoothHelper = bluetoothHelperMap[interfaceId] {
                                bluetoothHelper.disconnect(callbackFn: function)
                            } else {
                                sendBtError(interfaceId: interfaceId, interfaceFunc: function, error: "connection hasn't been made")
                            }
                        }
                    case "nfcScan":
                        if let function = callback?["function"] as? String {
                            guard NFCNDEFReaderSession.readingAvailable else {
                                let error = NSLocalizedString("NFCDeviceErrMsg", comment: "device doesn't support tag scanning")
                                webView.evaluateJavaScript("\(function)({'succeed' : false, 'message': '\(error)'})")
                                return
                            }
                            nfcCallbackFn = function
                            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
                            session?.alertMessage = NSLocalizedString("NFCScanMsg", comment: "Hold your iPhone near the nfc tag")
                            session?.begin()
                        }
                    case "appShare":
                        if let text = param?["text"] as? String {
                            let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                            activityViewController.completionWithItemsHandler = { (activity, success, items, error) in
                                if success {
                                    print("Sharing successful!")
                                } else {
                                    print("Sharing canceled!")
                                }
                            }
                            // For iPads: Necessary to prevent crash by specifying the source of the popover
                            /*if let popoverController = activityViewController.popoverPresentationController {
                                popoverController.sourceView = sender // Button that triggers the share sheet
                                popoverController.sourceRect = sender.bounds // Bounds of the button
                            }*/
                            self.present(activityViewController, animated: true, completion: nil)
                        }
                    case "closeApp":
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            exit(0)
                        }
                    case "initLogin":
                        if let erpAuthToken = self.erpAuthToken, let erpAppID = self.erpAppID {
                            initYlwAuth(authToken: erpAuthToken, appID: erpAppID)
                        } else if let customAuthDelegate = self.customAuthDelegate {
                            customAuthDelegate.onAuthTokenRequest()
                        }
                    default:
                        let appDoParam = CustomAction(action: action)

                        if let param = param {
                            for (key, value) in param {
                                appDoParam.param[key] = value
                            }
                        }
                        
                        if let callback = callback {
                            
                            let passresult: PassResultToWeb = {
                                struct PassResult: PassResultToWeb {
                                    var callback: [String:Any]
                                    var webview: WKWebView
                                    var action: String
                                    init(callback: [String:Any], webview: WKWebView, action: String) {
                                        self.callback = callback
                                        self.webview = webview
                                        self.action = action
                                    }
                                    func onResult(error: String?, result: String?) {
                                        do {
                                            if let callbackFunc = callback["function"] as? String,
                                               let runFunction = callback["runFunction"] as? String {
                                                let runJS: String
                                                if let error = error {
                                                    runJS = "\(callbackFunc)('\(runFunction)', '\(error)', \(result == nil ? "null" : "'\(result!)'"))"
                                                } else {
                                                    runJS = "\(callbackFunc)('\(runFunction)', null, \(result == nil ? "null" : "'\(result!)'"))"
                                                }
                                                webview.evaluateJavaScript(runJS) { (result, error) in
                                                    if let err = error {
                                                        print("Error CustomAction \(action): \(err.localizedDescription)")
                                                    }
                                                }
                                            }
                                        } catch {
                                            fatalError("Error constructing JavaScript call: \(error)")
                                        }
                                    }
                                }
                                var passer = PassResult(callback: callback, webview: webView, action: action)
                                return passer
                            }()
                            
                            customActionDelegate?.onCustomAction(customAction: appDoParam, passResultToWeb: passresult)
                        }
                        print(action)
                    }
                }
            }
        } else if let messageObject = message.body as? [String:Any] {
            let param = messageObject["param"] as? [String:Any]
            if let action = messageObject["action"] as? String {
                switch action {
                case "initSave":
                    if let saveID = param?["saveID"] as? String, let fileName = param?["fileName"] as? String {
                        self.destinationForFile(filename: fileName, saveID: saveID)
                    }
                case "fileChunk":
                    if let saveID = param?["saveID"] as? String, let b64 = param?["b64"] as? String {
                        if let fileSession = fileSessions[saveID], let chunk = Foundation.Data(base64Encoded: b64, options: .ignoreUnknownCharacters) {
                            fileSession.handle.seekToEndOfFile()
                            fileSession.handle.write(chunk)
                        } else if let fileData = imageData[saveID], let chunk = Foundation.Data(base64Encoded: b64, options: .ignoreUnknownCharacters) {
                            fileData.handle.seekToEndOfFile()
                            fileData.handle.write(chunk)
                        }
                    }
                case "fileComplete":
                    if let saveID = param?["saveID"] as? String, let fileName = param?["fileName"] as? String {
                        if let fileSession = fileSessions[saveID] {
                            fileSessions.removeValue(forKey: saveID)
                            fileSession.handle.closeFile()
                            if fileSession.isScoped {
                                fileSession.dir.stopAccessingSecurityScopedResource()
                            } else {
                                fileNamePicker(fileSession, saveID)
                            }
                        } else if let fileData = imageData[saveID] {
                            imageData.removeValue(forKey: saveID)
                            fileData.handle.closeFile()
                            PHPhotoLibrary.shared().performChanges({
                                let ext = (fileName as NSString).pathExtension.lowercased()
                                let type = UTType(filenameExtension: ext)
                                if let ut = type, ut.conforms(to: .image) {
                                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileData.url)
                                } else {
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileData.url)
                                }
                            }) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        print("Imported into Photos!")
                                        self.webView.evaluateJavaScript("showFileToast('\(fileName)', true)")
                                        do {
                                            try FileManager.default.removeItem(at: fileData.url)
                                            try FileManager.default.removeItem(at: fileData.dir)
                                        } catch { print("Couldn't delete temp:", error) }
                                    } else {
                                        print("Import failed:", error!)
                                        self.fileNamePicker(fileData, saveID)
                                    }
                                }
                            }
                        }
                    }
                case "download":
                    if let url = param?["url"] as? String, let fileName = param?["fileName"] as? String {
                        downloadUrl(url: url, filename: fileName)
                    }
                default:
                    break
                }
            }
        }
    }
    func buildFileDataXml(path: String, token: String, xmlns: String) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <FileData xmlns="\(xmlns)">
            <path>\(escapeXml(path))</path>
            <token>\(escapeXml(token))</token>
        </FileData>
        """
    }
    
    func escapeXml(_ input: String) -> String {
        return input
          .replacingOccurrences(of: "&",  with: "&amp;")
          .replacingOccurrences(of: "<",  with: "&lt;")
          .replacingOccurrences(of: ">",  with: "&gt;")
          .replacingOccurrences(of: "\"", with: "&quot;")
          .replacingOccurrences(of: "'",  with: "&apos;")
    }

    func postFileDataXml(to urlString: String, path: String, token: String, xmlns: String, fileName: String, completion: @escaping (Result<String, FileDataError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(FileDataError(message: "파일 다운로드 주소가 유효하지 않습니다.")))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let xmlPayload = buildFileDataXml(path: path, token: token, xmlns: xmlns)
        request.httpBody = Foundation.Data(xmlPayload.utf8)
        
        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in
            if let error = error {
                completion(.failure(FileDataError(message: error.localizedDescription)))
                return
            }
            
            guard
                let httpResp = response as? HTTPURLResponse,
                (200...299).contains(httpResp.statusCode)
            else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(FileDataError(message: "파일을 다운로드할 수 없습니다: \(code)")))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(FileDataError(message:  "파일을 다운로드할 수 없습니다.")))
                return
            }
            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                if FileManager.default.fileExists(atPath: tempUrl.path) {
                    try FileManager.default.removeItem(at: tempUrl)
                }
                try FileManager.default.copyItem(at: tempURL, to: tempUrl)
            } catch (let writeError) {
                completion(.failure(FileDataError(message:  writeError.localizedDescription)))
            }
            DispatchQueue.main.async {
                let picker = UIDocumentPickerViewController(
                    forExporting: [tempUrl],
                    asCopy: true
                )
                picker.modalPresentationStyle = .formSheet
                let del = ExportDelegate(tempURL: tempUrl, dir: nil, saveID: fileName, showFile: true, parent: self, completion: completion)
                picker.delegate = del
                self.activePickers[fileName] = picker
                objc_setAssociatedObject(picker, &del.associationKey, del, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.present(picker, animated: true)
            }
        }
        task.resume()
    }
    
    func destinationForFile(filename: String, saveID: String) {
      let ext = (filename as NSString).pathExtension.lowercased()
      guard let type = UTType(filenameExtension: ext) else {
          self.saveToTemp(filename: filename, saveID: saveID, isImg: false)
          //pickFolder(saveID: saveID, fileName: filename)
          return
      }
      if (type.conforms(to: .image) || type.conforms(to: .movie) || type.conforms(to: .video)) {
          ensurePhotoLibraryAccess { granted in
            if granted {
                self.saveToTemp(filename: filename, saveID: saveID, isImg: true)
            } else {
                self.saveToTemp(filename: filename, saveID: saveID, isImg: false)
                //self.webView.evaluateJavaScript("onSaveCancel('\(saveID)')", completionHandler: nil)
            }
          }
      } else {
          self.saveToTemp(filename: filename, saveID: saveID, isImg: false)
      }
    }
    
    func ensurePhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
        default:
            completion(false)
        }
    }
    
    fileprivate func saveToTemp(filename: String, saveID: String, isImg: Bool) {
        let tmpBase = FileManager.default.temporaryDirectory
        let sessionDir = tmpBase.appendingPathComponent(saveID, isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: sessionDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let tmpURL = sessionDir.appendingPathComponent(filename, isDirectory: false)
            FileManager.default.createFile(atPath: tmpURL.path, contents: nil, attributes: nil)
            let handle = try FileHandle(forWritingTo: tmpURL)
            if isImg {
                self.imageData[saveID] = FileSession(url: tmpURL, handle: handle, isScoped: false, dir: sessionDir)
            } else {
                self.fileSessions[saveID] = FileSession(url: tmpURL, handle: handle, isScoped: false, dir: sessionDir)
            }
            self.webView.evaluateJavaScript("onSaveReady('\(saveID)')", completionHandler: nil)
        } catch {
            print("Failed to open temp file:", error)
            self.webView.evaluateJavaScript("onSaveCancel('\(saveID)')", completionHandler: nil)
        }
    }
    
    fileprivate func fileNamePicker(_ fileSession: MainMasterDetailVC.FileSession, _ saveID: String) {
        let picker = UIDocumentPickerViewController(
            forExporting: [fileSession.url],
            asCopy: true
        )
        picker.modalPresentationStyle = .formSheet
        let del = ExportDelegate(tempURL: fileSession.url, dir: fileSession.dir, saveID: saveID, showFile: false, parent: self)
        picker.delegate = del
        activePickers[saveID] = picker
        objc_setAssociatedObject(picker, &del.associationKey, del, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.present(picker, animated: true)
    }
    
    func downloadUrl(url: String, filename: String) {
        let ext = (filename as NSString).pathExtension.lowercased()
        if let type = UTType(filenameExtension: ext), type.conforms(to: .image) || type.conforms(to: .movie) || type.conforms(to: .video) {
            ensurePhotoLibraryAccess { granted in
              if granted {
                  self.downloadFile(url: url, filename: filename, type: type)
              } else {
                  self.downloadFile(url: url, filename: filename, type: nil)
              }
            }
        } else {
            self.downloadFile(url: url, filename: filename, type: nil)
        }
    }
    
    func downloadFile(url: String, filename: String, type: UTType?) {
        if let fileURL = URL(string: url) {
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let request = URLRequest(url:fileURL)
            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    do {
                        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                        
                        if FileManager.default.fileExists(atPath: tempUrl.path) {
                            try FileManager.default.removeItem(at: tempUrl)
                        }
                        try FileManager.default.copyItem(at: tempLocalUrl, to: tempUrl)
                        if let ut = type {
                            PHPhotoLibrary.shared().performChanges({
                                if ut.conforms(to: .image) {
                                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempUrl)
                                } else {
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempUrl)
                                }
                            }) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        self.webView.evaluateJavaScript("showFileToast('\(filename)', true)")
                                        print("Imported into Photos!")
                                        do {
                                            try FileManager.default.removeItem(at: tempUrl)
                                        } catch { print("Couldn't delete temp:", error) }
                                    } else {
                                        print("Import failed:", error!)
                                        self.fileNamePicker(tempUrl, filename)
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.fileNamePicker(tempUrl, filename)
                            }
                        }
                    } catch {
                    }
                }
            }
            task.resume()
        }
        
    }
    
    fileprivate func fileNamePicker(_ tempUrl: URL, _ filename: String) {
        let picker = UIDocumentPickerViewController(
            forExporting: [tempUrl],
            asCopy: true
        )
        picker.modalPresentationStyle = .formSheet
        let del = ExportDelegate(tempURL: tempUrl, dir: nil, saveID: filename, showFile: false, parent: self)
        picker.delegate = del
        self.activePickers[filename] = picker
        objc_setAssociatedObject(picker, &del.associationKey, del, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.present(picker, animated: true)
    }
    
    public func setFlexAppID(fAppID: String) {
        self.flexAppID = fAppID
    }
    
    public func setLinkParam(linkParam: String) {
        self.linkParam = linkParam
    }

    public func setLimitNavigation(limitsNavigationsToAppBoundDomains: Bool) {
        self.limitsNavigationsToAppBoundDomains = limitsNavigationsToAppBoundDomains
    }
    
    public func setCustomActionDelegate(delegate: CustomActionDelegate) {
        self.customActionDelegate = delegate
    }
    
    public func setCustomAuthDelegate(delegate: CustomAuthDelegate) {
        self.customAuthDelegate = delegate
    }
    

    public func initYlwAuth(authToken: String, appID: String) {
        let runJS: String = "initYlwAuth('\(authToken)', '\(appID)')"
        if let webView = self.webView {
            webView.evaluateJavaScript(runJS) { [self] (result, error) in
                if let err = error {
                    print("Error initYlwAuth \(appID): \(err.localizedDescription)")
                    self.erpAuthToken = authToken
                    self.erpAppID = appID
                } else {
                    self.erpAuthToken = nil
                    self.erpAppID = nil
                }
            }
        } else {
            self.erpAuthToken = authToken
            self.erpAppID = appID
        }
    }
    
    func webFileDownload(id:String, serviceURL:String, bis:String, filePath:String,callback:String){
        //        https:///webdevmobile.ksystemace.com/FlexSvc/api/FileDownload?SessionId=test&ServerId=bpodev_bis&FileFullPath=C:\temp\test.pdf
        //create url use FileServiceURL :: BaseUserValue.SERVERIP_VALUE
        var fileurl_str = serviceURL + "/FlexSvc/api/FileDownload"
        var get_param = "?SessionId=\(BaseUserValue.SESSION_ID)&ServerId=\(bis)&FileFullPath=\(filePath)"
        get_param = get_param.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        fileurl_str = fileurl_str + get_param
        
        if fileurl_str.isEmpty {
            print("url is empty")
//            오류 - 파일 다운로드 주소를 찾을 수 없습니다.
//            result : {
//                 status : {
//                     succeed : true/false
//                     code : "fail"
//                 }
//            }
            DispatchQueue.main.async { [unowned self] in
            let js = callback + "('" + id + "', {'status' : {'succeed' : false,'code' : '파일 다운로드 주소를 찾을 수 없습니다.'}})"
                self.webView.evaluateJavaScript(js)
            }
            return
        }
        
        if let fileName = filePath.components(separatedBy: "\\").last {
            // Create destination URL
            if let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let destinationFileUrl = documentsUrl.appendingPathComponent(fileName)
                   
                //Create URL to the source file you want to download
                if let fileURL = URL(string: fileurl_str) {
                    let sessionConfig = URLSessionConfiguration.default
                    let session = URLSession(configuration: sessionConfig)
                
                    let request = URLRequest(url:fileURL)
                   
                    let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                        if let tempLocalUrl = tempLocalUrl, error == nil {
                            // Success
    //                        (response as? HTTPURLResponse)?.statusCode
//                            let fileData = NSData(contentsOf: tempLocalUrl)
                            do {
                                if FileManager.default.fileExists(atPath: destinationFileUrl.path) {
                                    try FileManager.default.removeItem(at: destinationFileUrl)
                                }
                                try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
    //                          성공
                                DispatchQueue.main.async { [unowned self] in
                                    let documentInteractionController = UIDocumentInteractionController()
                                    documentInteractionController.url = destinationFileUrl
                                    documentInteractionController.uti = destinationFileUrl.uti
                                    documentInteractionController.delegate = self
                                    if documentInteractionController.presentPreview(animated: true) {
                                        let js = callback + "('" + id + "', {'status' : {'succeed' : true,'code' : ''}})"
                                        self.webView.evaluateJavaScript(js)
                                    } else {
                                        let js = callback + "('" + id + "', {'status' : {'succeed' : false,'code' : 'no preview'}})"
                                        self.webView.evaluateJavaScript(js)
                                        let vc = UIActivityViewController(activityItems: [destinationFileUrl], applicationActivities: nil)
                                        self.present(vc, animated: true, completion: {
                                            DispatchQueue.main.async { [unowned self] in
                                                let js = callback + "('" + id + "', {'status' : {'succeed' : true,'code' : ''}})"
                                                self.webView.evaluateJavaScript(js)
                                            }
                                        })
                                    }
                                }
                            } catch (let writeError) {
    //                            오류 - writeError
                                DispatchQueue.main.async { [unowned self] in
                                    let js = callback + "({'status' : {'succeed' : false,'code' : '\(writeError)'}})"
                                    self.webView.evaluateJavaScript(js)
                                }
                                print("Error creating a file \(destinationFileUrl) : \(writeError)")
                            }
                           
                        } else {
    //                      오류 - error?.localizedDescription ?? "파일 저장이 불가능합니다."
                            DispatchQueue.main.async { [unowned self] in
                                let js = callback + "({'status' : {'succeed' : false,'code' : '\(error?.localizedDescription ?? "파일 저장이 불가능합니다.")'}})"
                                self.webView.evaluateJavaScript(js)
                            }
                            print("Error took place while downloading a file. Error description: %@", error?.localizedDescription ?? "Error!");
                        }
                    }
                    task.resume()
                }
                else {
    //              오류 - 파일 다운로드 주소가 유효하지 않습니다.
                    DispatchQueue.main.async { [unowned self] in
                        let js = callback + "({'status' : {'succeed' : false,'code' : '파일 다운로드 주소가 유효하지 않습니다.'}})"
                        self.webView.evaluateJavaScript(js)
                    }
                }
            }
            else {
    //          오류 - 디바이스 폴더 경로를 찾을 수 없습니다.
                DispatchQueue.main.async { [unowned self] in
                    let js = callback + "({'status' : {'succeed' : false,'code' : '디바이스 폴더 경로를 찾을 수 없습니다.'}})"
                    self.webView.evaluateJavaScript(js)
                }
            }
        }
        else {
//          오류 - 파일 경로가 유효하지 않습니다.
            DispatchQueue.main.async { [unowned self] in
                let js = callback + "({'status' : {'succeed' : false,'code' : '파일 경로가 유효하지 않습니다.'}})"
                self.webView.evaluateJavaScript(js)
            }
        }
    }
    @objc func returnResultByCallJS(_ noti:Notification){
        if let js = noti.object as? String {
            webView.evaluateJavaScript(js)
        }
    }
    
    static func getUserProfileImageURL(empSeq: String) -> URL? {
        let urlString = Util.getDownloadImageURL(orgFileType: Const.ORG_FILE_TYPE.THUMB, fileName: CommonConstants.ORG_FILENAME + empSeq + CommonConstants.JPG)
        
        if let url = URL.init(string: urlString) {
            return url
        } else {
            return nil
        }
    }

    
    ////CLLocationManagerDelegate////
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        lcModule?.stop()
//        let userLocation:CLLocation = locations[0] as CLLocation
//        lcModule?.handleResult(result: userLocation)
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
//    {
//        lcModule?.fail()
//        print("fail : \(error)")
//    }
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        lcModule?.branchByAuth(isFirst: false)
//    }
//    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
//        lcModule?.fail()
//        print("Failed monitoring region: \(error.localizedDescription)")
//    }
//    //for BeaconConnectVC
//    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
//        print(region)
//        print(beacons)
//        print(manager)
//        
//        for beacon in beacons {
//            if region.proximityUUID == beacon.proximityUUID {
//                lcModule?.handleResult(result: region)
//                break
//            }
//        }
//    }
}

// Delegate implementtion for MODULE MENU Collection View
extension MainMasterDetailVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuModuleData.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ModuleMenuCollectionViewCell", for: indexPath) as! ModuleMenuCollectionViewCell
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        let moduleLabelText = menuModuleData[indexPath.item].title
        cell.moduleLabel.text = moduleLabelText
        //cell.moduleImgView.image = UIImage(named: menuModuleData[indexPath.item].iconName ?? "")
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        webViewModuleTapped(index: indexPath.item)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sideSize = (moduleMenuCollectionView.contentSize.width - CGFloat(numberOfCellsToDisplayHorizontally - 1) * cellSpacing) / CGFloat(numberOfCellsToDisplayHorizontally)
        return CGSize(width: sideSize, height: sideSize)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = YLWColorUtils.changeHexToUIColor(ColorConstants.menusearchButtonBackgroundColor, opacity: 0.3)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.white
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}

extension MainMasterDetailVC: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true//touch.view == gestureRecognizer.view
    }
}

//extension MainMasterDetailVC: CommonSvcCallerResult {
//
//    func OnReceiveCommonResult(_ dsData: DataSet, serviceName: String, SP: String, ErrorCode: String) {
//        CFRunLoopStop(CFRunLoopGetMain())
//        stopSpinner()
//
//        //Handling service error response
//        if ErrorCode.contains(WebConst.WEBSVC_TIMEOUT) || ErrorCode.contains(WebConst.WEBSVC_ERROR) {
//            DispatchQueue.main.async (execute: { [unowned self] in
//                MainViewController.removeSpinner(spinner: MainViewController.spinnerBackgroundView)
//                self.moduleMenuCollectionView.reloadData()
//                self.reloadBtn.isHidden = false
//            })
//
//            return
//        }
//
//        reloadBtn.isHidden = true
//
//        let tables = dsData.m_Tables!.tables
//        if tables.count > 1, let versionCheckArray = tables[1].m_rows?.rows, versionCheckArray.count > 0 {
//            let app_version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
//            let limit_version = versionCheckArray[0].getValueByColumnName("ver_iOS") ?? ""
//
//            //현재 앱버전이 정책 최소사용 버전보다 낮으면 설치페이지로 이동시킨다.
//            if LoginUtil.compareAppVersion(basic_version: app_version, compare_version: limit_version) {
//                if let installLink = versionCheckArray[0].getValueByColumnName("URL") {
//                    if let url = URL(string: installLink) {
//                        if UIApplication.shared.canOpenURL(url) {
//                            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
//                                print("Open url : \(success)")
//                                //강제종료
//                                exit(0)
//                            })
//                        }
//                    }
//                }
//                return
//            }
//        }
//        if tables.count > 0, let papersDataArray = tables[0].m_rows?.rows, papersDataArray.count > 0, (papersDataArray[0].getValueByColumnName("Status")!.isEmpty && papersDataArray[0].getValueByColumnName("Result")!.isEmpty) {
//            if SP == CommonConstants._SCAMobileQueryDemoMenu {
//                for module in papersDataArray {
//                    let seq = module.getValueByColumnName("Seq") ?? ""
//                    let menuOrder = module.getValueByColumnName("MenuOrder") ?? ""
//                    let title = module.getValueByColumnName("Title") ?? ""
//                    let link = module.getValueByColumnName("Link") ?? ""
//                    let iconName = module.getValueByColumnName("IconName") ?? ""
//
//                    menuModuleData.append(MenuModule(seq: seq, menuOrder: menuOrder, title: title, link: link, iconName: iconName))
//                }
//                moduleMenuCollectionView.reloadData()
//            }
//        }
//    }
//}

extension MainMasterDetailVC: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let limit = limitsNavigationsToAppBoundDomains {
            configuration.limitsNavigationsToAppBoundDomains = limit;
        }
        // Create new WKWebView with custom configuration here
        //let configuration = WKWebViewConfiguration()
//        configuration.userContentController = contentController
        return WKWebView(frame: webView.frame, configuration: configuration)
    }
    
}

extension MainMasterDetailVC: MasterDetailActionDelegate {
    
    @objc func toggleMenuPanel() {
        view.endEditing(true)
        if (menuLeadingContraint.constant < 0) {
            //SHOW MENU PANEL
            self.openMenuDrawer()
        } else {
            //HIDE MENU PANEL
            self.closeMenuDrawer()
        }
    }
}
struct FileDataError: Error {
  let message: String
}
class ExportDelegate: NSObject, UIDocumentPickerDelegate {
    private static var counter: UInt8 = 0
    public var associationKey: UInt8 = 0
    weak var parent: MainMasterDetailVC?
    let tempURL: URL
    let dir: URL?
    let saveID: String
    let showFile: Bool
    let completion: ((Result<String, FileDataError>) -> Void)?
    init(tempURL: URL, dir: URL?, saveID: String, showFile: Bool, parent: MainMasterDetailVC?, completion: ((Result<String, FileDataError>) -> Void)? = nil) {
        if ExportDelegate.counter < 255 {
            self.associationKey = ExportDelegate.counter + 1
        } else {
            self.associationKey = 0
        }
        ExportDelegate.counter = self.associationKey
        self.tempURL = tempURL
        self.dir = dir
        self.saveID = saveID
        self.parent = parent
        self.showFile = showFile
        self.completion = completion
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if self.showFile , let url = urls.first {
            if QLPreviewController.canPreview(url as QLPreviewItem) {
                let preview = QLPreviewController()
                preview.modalPresentationStyle = .overCurrentContext//.overFullScreen//.formSheet//.pageSheet//
                parent?.definesPresentationContext = true
                preview.dataSource = parent
                parent?.previewUrl = url
                preview.view.backgroundColor = .clear
        
                if #available(iOS 15.0, *) {
                    if let sheet = preview.sheetPresentationController {
                        sheet.detents = [.large()]
                        sheet.largestUndimmedDetentIdentifier = .large
                        sheet.prefersGrabberVisible = true
                    }
                }
                parent?.present(preview, animated: true) {
                    self.parent?.previewUrl = nil
                    self.completion?(.success(""))
                }
                return
            } else {
                self.completion?(.success("no preview"))
            }
        } else if let fileName = urls.first?.lastPathComponent, !fileName.isEmpty {
            self.parent?.webView.evaluateJavaScript("showFileToast('\(fileName)')")
        }
        cleanup(controller)
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        cleanup(controller)
    }
    private func cleanup(_ controller: UIDocumentPickerViewController) {
        DispatchQueue.main.async {
            objc_setAssociatedObject(controller, &self.associationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.parent?.activePickers.removeValue(forKey: self.saveID)
            self.parent = nil
        }
        do {
            try FileManager.default.removeItem(at: tempURL)
            guard let dir = dir else { return }
            try FileManager.default.removeItem(at: dir)
        } catch { print("Cleanup failed:", error) }
    }
}

extension UIButton {
    func aligTextCenterX() {
        guard let imageViewSize = self.imageView?.frame.size else { return }
        titleEdgeInsets.left = -imageViewSize.width
    }
}

extension URL {
    var uti: String {
        return (try? self.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier ?? "public.data"
    }
}
extension MainMasterDetailVC: UIDocumentInteractionControllerDelegate, QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewUrl == nil ? 0 : 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        guard let url = previewUrl else {
            fatalError("Quick Look asked for an item when none exists")
        }
        return url as QLPreviewItem
    }
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
 }
}
