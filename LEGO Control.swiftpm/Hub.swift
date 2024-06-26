import Combine
import CoreBluetooth

private let serviceUUID = CBUUID(string: "00001623-1212-EFDE-1623-785FEABCD123")
private let characteristicUUID = CBUUID(string: "00001624-1212-EFDE-1623-785FEABCD123")

@MainActor
final class Hub: NSObject, ObservableObject {
    private let centralManager = CBCentralManager()
    
    @Published var isConnecting = false
    @Published var isReady = false
    @Published var connectingPeripheral: CBPeripheral?
    private weak var lwpCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager.delegate = self
        centralManager.publisher(for: \.isScanning).assign(to: &$isConnecting)
    }
    
    func connect() {
        guard centralManager.state == .poweredOn else { return }
        
        // Step 1: Scan
        // centralManager.scanForPeripherals(withServices: nil)
        // or
        // centralManager.scanForPeripherals(withServices: [serviceUUID])
    }
    
    func cancelConnecting() {
        centralManager.stopScan()
        disconnect()
    }
    
    func disconnect() {
        if let peripheral = connectingPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

extension Hub: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Found:", peripheral.name ?? "No name", RSSI)
        
        if connectingPeripheral == nil /* && peripheral.name == "YOUR_HUB_NAME" */ {
            connectingPeripheral = peripheral
            
            // Step 2: Connect
            // centralManager.connect(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(#function)
        peripheral.delegate = self
        
        // Step 3: Discover Service
        // peripheral.discoverServices(nil)
        // or
        // peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(#function)
        connectingPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(#function)
        connectingPeripheral = nil
        isReady = false
    }
}

extension Hub: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(#function)
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            centralManager.cancelPeripheralConnection(peripheral)
            return            
        }
        
        // Step 4: Discover Characteristic
        // peripheral.discoverCharacteristics(nil, for: service)
        // or
        // peripheral.discoverCharacteristics([characteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print(#function)
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            centralManager.cancelPeripheralConnection(peripheral)
            return            
        }
        lwpCharacteristic = characteristic
        centralManager.stopScan()
        isReady = true
        
        // Step 6: Enable Notifications
        // peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("[notify]", characteristic.value?.hexString ?? "")
    }
}

extension Hub {
    func write(_ data: Data) {
        guard let connectingPeripheral, let lwpCharacteristic else { return }
        print("[write]", data.hexString)
        
        // Step 5: Write
        // connectingPeripheral.writeValue(data, for: lwpCharacteristic, type: .withResponse)
        // or
        // connectingPeripheral.writeValue(data, for: lwpCharacteristic, type: .withoutResponse)
    }
}

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            "unknown"
        case .resetting:
            "resetting"
        case .unsupported:
            "unsupported"
        case .unauthorized:
            "unauthorized"
        case .poweredOff:
            "poweredOff"
        case .poweredOn:
            "poweredOn"
        @unknown default:
            "@unknown default"
        }
    }
}
