import Foundation
import CoreBluetooth

protocol BluetoothResults {
    
    func onSearchResult(interfaceId: String, callbackFn: String, error: String?, le: [String : String]);
    func onResult(interfaceId: String, callbackFn: String, error: String?);
    
    func onMessage(interfaceId: String, callbackFn: String, data: String, uuid: String);
}

class BluetoothHelper/*: CBCentralManagerDelegate, CBPeripheralDelegate*/ : NSObject, CBCentralManagerDelegate, ObservableObject, CBPeripheralDelegate{
    @Published var isBluetoothEnabled = false
    @Published var discoveredPeripherals = [CBPeripheral]()
    var bluetoothResults: BluetoothResults?
    var interfaceId: String?
    var settingTimer:Timer?
    var searchTimer:Timer?
    var connectTimer:Timer?
    var lastCallbackFn: String?
    var searchCallbackFn: String?
    var connectCallbackFn: String?
    var sendCallbackFn: String?
    var disconnectCallbackFn: String?
    var receiveMessageFn: String?
    var isInitialized = false
    var isSearchPending = false
    var isConnectPending = false
    var peripheralAddress: String?
    var le: [String : String] = [:]
    var writeChar: CBCharacteristic?
    var writeWithoutResChar: CBCharacteristic?
    var connectedPeripheral: CBPeripheral?
    var peripheralTarget: CBPeripheral?
    
    private var centralManager: CBCentralManager!
    
    //override
    init(interfaceId: String, callbackFn: String, bluetoothResults: BluetoothResults ) {
        super.init()
        self.bluetoothResults = bluetoothResults
        self.interfaceId = interfaceId
        self.lastCallbackFn = callbackFn
        //let options: [String: Any] = [CBCentralManagerOptionShowPowerAlertKey: false]
        centralManager = CBCentralManager(delegate: self, queue: nil)//, options: options)
    }
    
    func search(callbackFn: String) {
        lastCallbackFn = callbackFn
        searchCallbackFn = callbackFn
        if (isInitialized && !isBluetoothEnabled) {
            isSearchPending = true
            centralManager = CBCentralManager(delegate: self, queue: nil)
        } else if (isBluetoothEnabled){
            startSearchTimer()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            isSearchPending = true
        }
    }
    
    fileprivate func connectToPeripheral(_ address: String) {
        let targetUUID = UUID(uuidString: address)!
        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [targetUUID])
        centralManager?.stopScan()
        if let peripheral = peripherals?.first {
            peripheralTarget = peripheral
            peripheralTarget?.delegate = self
            centralManager?.connect(peripheralTarget!, options: nil)
        } else if let callbackFn = connectCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: "Peripheral not found")
        }
    }
    
    func connect(address: String, callbackFn: String, receiveMessageFn: String?) {
        if let connectedP = connectedPeripheral {
            //
            bluetoothResults?.onResult(interfaceId: interfaceId ?? "", callbackFn: callbackFn, error: "Already connected to \(connectedP.name ?? connectedP.identifier.uuidString).")
            return
        }
        lastCallbackFn = callbackFn
        self.receiveMessageFn = receiveMessageFn
        self.connectCallbackFn = callbackFn
        self.peripheralAddress = address
        if (isInitialized && !isBluetoothEnabled) {
            isConnectPending = true
            centralManager = CBCentralManager(delegate: self, queue: nil)
        } else if (isBluetoothEnabled){
            startConnectTimer()
            connectToPeripheral(address)
        } else {
            isConnectPending = true
        }
    }
    
    func send(value: String, callbackFn: String) {
        if let charac = writeChar {
            self.sendCallbackFn = callbackFn
            let dataToSend = value.data(using: .utf8)!
            //connectedPeripheral?.writeValue(dataToSend, for: charac, type: .withResponse)//withResponse is responding with incorrect error
            connectedPeripheral?.writeValue(dataToSend, for: charac, type: .withoutResponse)
            if let iid = interfaceId {
                bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: nil)
            }
        } else if let charac = writeWithoutResChar {
            let dataToSend = value.data(using: .utf8)!
            connectedPeripheral?.writeValue(dataToSend, for: charac, type: .withoutResponse)
            if let iid = interfaceId {
                bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: nil)
            }
        }
    }
    
    func disconnect(callbackFn: String) {
        guard let peripheral = connectedPeripheral else {
            if let iid = interfaceId {
                bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: "No peripheral to disconnect")
            }
            return
        }
        self.disconnectCallbackFn = callbackFn
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = false
        if central.state == .unauthorized {
            //send no permission error
            if let callbackFn = lastCallbackFn, let iid = interfaceId {
                bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: "Bluetooth permission is required.")
            }
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        } else if central.state == .poweredOn {
            cancelSettingTimer()
            isBluetoothEnabled = true
            if isSearchPending {
                isSearchPending = false
                startSearchTimer()
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
            if isConnectPending, let address = peripheralAddress {
                isConnectPending = false
                startConnectTimer()
                connectToPeripheral(address)
            }
        } else {
            cancelSettingTimer()
            settingTimer = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(onSettingUp), userInfo: nil, repeats: true)
        }
        isInitialized = true
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
        if let name = peripheral.name {
            let id = peripheral.identifier.uuidString
            if let value = le[id] {
                if (value != name) {
                    le[id] = name
                }
            } else {
                le[id] = name
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Successfully connected to peripheral: \(peripheral.identifier.uuidString)")
        cancelConnectTimer()
        connectedPeripheral = peripheral
        peripheral.discoverServices(nil) // Start discovering services if needed
        if let callbackFn = connectCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.identifier.uuidString). Error: \(error?.localizedDescription ?? "Unknown error")")
        if let callbackFn = connectCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: error?.localizedDescription ?? "Unknown error")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let callbackFn = sendCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: error?.localizedDescription)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.identifier.uuidString). Error: \(error?.localizedDescription ?? "No error")")
        if let callbackFn = disconnectCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: nil)
        }
        writeChar = nil
        writeWithoutResChar = nil
        connectedPeripheral = nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let services = peripheral.services {
            for service in services {
                print("Discovered service: \(service.uuid)")
                // Discover characteristics if needed
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.notify) {
                    print("Characteristic \(characteristic.uuid) can notify")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.properties.contains(.write) {
                    print("Characteristic \(characteristic.uuid) can write")
                    writeChar = characteristic
                    //peripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
                }
                if characteristic.properties.contains(.writeWithoutResponse) {
                    print("Characteristic \(characteristic.uuid) can writeWithoutResponse")
                    writeWithoutResChar =  characteristic
                }
                //print("Discovered characteristic: \(characteristic.uuid)")
                // Perform read/write/notify operations if needed
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notifications started for \(characteristic.uuid)")
        } else {
            print("Notifications stopped for \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let data = characteristic.value {
            let receivedString = String(data: data, encoding: .utf8)
            if let callbackFn = receiveMessageFn, let iid = interfaceId, let receivedString = receivedString {
                print("received: \(receivedString)")
                bluetoothResults?.onMessage(interfaceId: iid, callbackFn: callbackFn, data: receivedString, uuid: characteristic.uuid.uuidString);
            }
        }
    }
    
    @objc func onSettingUp() {
        cancelSettingTimer()
        var state: String?
        switch centralManager?.state {
        case .poweredOff:
            state = "Is Powered Off."
        case .poweredOn:
            isBluetoothEnabled = true//startScanning()
            if isSearchPending {
                isSearchPending = false
                startSearchTimer()
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
            if isConnectPending, let address = peripheralAddress {
                isConnectPending = false
                startConnectTimer()
                connectToPeripheral(address)
            }
        case .unsupported:
            state = "Is Unsupported."
        case .unauthorized:
            state = "Is Unauthorized."
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        case .unknown:
            state = "Unknown."
        case .resetting:
            state = "Resetting."
        case .none:
            state = "None."
        @unknown default:
            state = "Unknown default."
        }
        if let err = state, let callbackFn = lastCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: err)
        }
    }
    
    func cancelSettingTimer() {
        settingTimer?.invalidate()
        settingTimer = nil
    }
    
    func cancelConnectTimer() {
        connectTimer?.invalidate()
        connectTimer = nil
    }
    
    func startSearchTimer() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(onSearchUp), userInfo: nil, repeats: true)
    }
    
    func startConnectTimer() {
        connectTimer?.invalidate()
        connectTimer = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(onConnectUp), userInfo: nil, repeats: true)
    }
    
    @objc func onSearchUp() {
        centralManager?.stopScan()
        searchTimer?.invalidate()
        searchTimer = nil
        if let callbackFn = searchCallbackFn, let iid = interfaceId {
            bluetoothResults?.onSearchResult(interfaceId: iid, callbackFn: callbackFn, error: nil, le: le);
            //bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: err)
        }
        
    }
    
    @objc func onConnectUp() {
        connectTimer?.invalidate()
        connectTimer = nil
        if let callbackFn = connectCallbackFn, let iid = interfaceId {
            bluetoothResults?.onResult(interfaceId: iid, callbackFn: callbackFn, error: "Failed to connect")
        }
    }
    
    func toggleBluetooth() {
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
            centralManager = nil
        } else {
            let options: [String: Any] = [CBCentralManagerOptionShowPowerAlertKey: true]
            centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
        }
    }
}
