//
//  ViewController.swift
//  Hear_BLE
//
//  Created by Alex.Lingjiahua on 2022/4/14.
//

import UIKit
import CoreBluetooth

/// 蓝牙状态
enum BleState: Int {
    case ready
    case scanning
    case connecting
    case connected
}


///传出蓝牙当前连接的设备发送过来的信息
typealias BleDataBlock = (_ data: Data) -> Void
///传出蓝牙当前搜索到的设备信息
typealias BlePeripheralsBlock = (_ pArray: [CBPeripheral]) -> Void
//当设备连接成功时，记录该设备，用于请求设备版本号
typealias BleConnectedBlock = (_ peripheral: CBPeripheral, _ characteristic:CBCharacteristic) -> Void


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //    中心管理员
    var theManager: CBCentralManager!
   
    //    设备
    var thePerpher: CBPeripheral?
    
    //    发命令的特征
    var theSakeCC: CBCharacteristic!
    
    //
    private let BLE_WRITE_UUID = "00001101-D102-11E1-9B23-00025B00A5A5"
    private let BLE_NOTIFY_UUID = "00001103-D102-11E1-9B23-00025B00A5A5"
    
    //传出数据
    var backDataBlock: BleDataBlock?
    
    /// 外设数组
    var peripheralArray = NSMutableArray.init()
    
    ///扫描到的所有设备
    var aPeArray: [CBPeripheral] = []
    
    // 连接设备按钮
    var button: UIButton? = UIButton.init()
    
    // 断开连接按钮
    var cutLinkBtn: UIButton? = UIButton.init()
    
    // 停止扫描按钮
    var stopBtn: UIButton? = UIButton.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

       
        setUI();
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("CBCentralManager state:", "unknown")
            break
        case .resetting:
            print("CBCentralManager state:", "resetting")
            break
        case .unsupported:
            print("CBCentralManager state:", "unsupported")
            break
        case .unauthorized:
            print("CBCentralManager state:", "unauthorized")
            break
        case .poweredOff:
            print("CBCentralManager state:", "poweredOff")
            break
        case .poweredOn:
            print("CBCentralManager state:", "poweredOn")
           
            // 第一个参数那里表示扫描带有相关服务的外部设备，例如填写@[[CBUUIDUUIDWithString:@"需要连接的外部设备的服务的UUID"]]，即表示带有需要连接的外部设备的服务的UUID的外部设备，nil表示扫描全部设备；
            //MARK: -3.扫描周围外设（支持蓝牙）
            theManager.scanForPeripherals(withServices: nil, options: nil)// 每次搜索到一个外设都会回调起代理方法centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
            break
        default:
            print("未知状态")
            break
        }
        
        print("\(central.state)")
    }
    

    
    func setUI() {
        button?.frame = CGRect(x: (view.frame.width - 200)/2, y: 30, width: 200, height: 80)
        button?.backgroundColor = UIColor.blue
        button?.setTitle("连接设备", for: .normal)
        button?.setTitleColor(UIColor.white, for: .normal)
        button?.layer.cornerRadius = 10
        button?.addTarget(self, action: #selector(doConnect), for: .touchUpInside)
        self.view.addSubview(button!)
        
        cutLinkBtn?.frame = CGRect(x: (view.frame.width - 200)/2, y: button!.frame.origin.y + 130, width: 200, height: 80)
        cutLinkBtn?.setTitle("断开连接", for: .normal)
        cutLinkBtn?.setTitleColor(UIColor.white, for: .normal)
        cutLinkBtn?.backgroundColor = UIColor.blue
        cutLinkBtn?.layer.cornerRadius = 10
        cutLinkBtn?.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        self.view.addSubview(cutLinkBtn!)
        
        stopBtn?.frame = CGRect(x: (view.frame.width - 200)/2, y: cutLinkBtn!.frame.origin.y + 100, width: 200, height: 80)
        stopBtn?.setTitle("停止扫描", for: .normal)
        stopBtn?.setTitleColor(UIColor.white, for: .normal)
        stopBtn?.backgroundColor = UIColor.blue
        stopBtn?.layer.cornerRadius = 10
        stopBtn?.addTarget(self, action: #selector(stopScan), for: .touchUpInside)
        self.view.addSubview(stopBtn!)
    }
    
    
    ///停止扫描
    @objc func stopScan() {
        theManager?.stopScan()
        print("停止扫描成功")
    }
    
    ///断开连接
   @objc func cancel() {
       
       
       theManager.cancelPeripheralConnection(aPeArray[0])
       // 是否再重新扫描
//       theManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    //连接指定的设备
   @objc func doConnect(peripheral: CBPeripheral) {
       // 初始化
       theManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //主动获取搜索到的peripheral列表
    func getPeripheralList() -> [CBPeripheral] {
        return aPeArray
    }
    
    
    //MARK: -4.发现外设
    /// 搜索到外设会的回调方法
    ///
    /// - Parameters:
    ///   - central: 中心设备实例对象
    ///   - peripheral: 外设实例对象
    ///   - advertisementData: 一个包含任何广播和扫描响应数据的字典
    ///   - RSSI: 外设的蓝牙信息强度
    // 发现外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name != nil {
            print("搜索蓝牙设备中····\(peripheral.name)")
            
            if peripheral.name == "Allway Halo 20 APP" {
                
                print("搜索可连接的蓝牙设备为：\(peripheral.name)")
                // 添加外设到外设数组（如果不保存这个外设或者说没有对这个外设对象有个强引用的话，就没有办法到达连接成功的方法，因此没有强引用的话，这个方法过后，就销毁外设对象了）
                // 连接外设成功或者失败分别会进入回调方法
                // MAKE: -连接外设
                peripheralArray.add(peripheral)
                // 或者，你可以建立一个全局的外设对象。例如
                //        self.peripheral = peripheral  这就是强引用这个局部的外设对象，这样就不会导致出了这个方法这个外设对象就被销毁了

                // 停止扫描外设
                theManager.stopScan()
                //MARK: -5.连接外设
                // 添加完后，就开始连接外设
                theManager.connect(peripheral, options: nil)
                print("发现蓝牙设备：  \(peripheralArray)")
                aPeArray.append(peripheral)
               
            }
        }
       
       
        // 如果你扫描到多个外设，要连接特定的外设，可以用以下方法
//        if peripheral.name == "LE-Allway F20 Pro" {
//            // 连接设备
//            central.connect(peripheral, options: nil)
//
//        }
//        //
       
    }

    //MARK: -6.连接成功，扫描外设服务
    // 连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("连接成功")
        
        // 连接成绩后，接下来就要开始对外设进行寻找服务 特征 读写，所以要开始用到外设的代理方法，所以这里要设置外设的代理为当前控制器
        peripheral.delegate = self
        
        // 设置完后，就开始扫描外设的服务
        // 参数设了nil，是扫描所有服务，如果你知道你想要的服务的UUID，那么也可以填写指定的UUID
        peripheral.discoverServices(nil) //这里会回调代理peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)  这里方法里有这个外设的服务信息
        
    }
    
    // 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    
    // 与外设断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("断开连接的设备名称为: \(peripheral.name)")
        
    }
    
    //MARK: -7.发现服务，遍历服务，扫描服务下的特征
    // 外设的服务信息
    //MARK: 匹配对应服务UUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)// 发现特征，第二个参数填哪个服务的特征，这个方法会回调特征信息的方法
            print("服务UUID：\(service.uuid.uuidString)")
        }
    }
    
    //MARK: -8.发现特征
    //  特征信息的方法
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("\(service.uuid.uuidString)服务下的特性:\(characteristic)")
            if characteristic.uuid == CBUUID (string: BLE_WRITE_UUID)  {
                //MARK: -9.读取指定特征的信息
                //读取特征数据
                peripheral.readValue(for: characteristic)//读取都就会进入didUpdate的代理方法
            }
            
            if  characteristic.uuid == CBUUID (string: BLE_NOTIFY_UUID) {
                //订阅通知
                /**
                 -- 通知一般在蓝牙设备状态变化时会发出，比如蓝牙音箱按了上一首或者调整了音量，如果这时候对应的特征被订阅，那么app就可能收到通知
                 -- 阅读文档查看需要对该特征的操作
                 -- 订阅成功后回调didUpdateNotificationStateForCharacteristic
                 -- 订阅后characteristic的值发生变化会发送通知到didUpdateValueForCharacteristic
                 -- 取消订阅：设置setNotifyValue为NO
                 */
                //这里我们可以使用readValueForCharacteristic:来读取数据。如果数据是不断更新的，则可以使用setNotifyValue:forCharacteristic:来实现只要有新数据，就获取。
                peripheral.setNotifyValue(true, for: characteristic)
            }
            //此处代表连接成功
            //扫描描述
            /**
             -- 进一步提供characteristic的值的相关信息。（因为我项目里没有的特征没有进一步描述，所以我也不怎么理解）
             -- 当发现characteristic有descriptor,回调didDiscoverDescriptorsForCharacteristic
             */
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    //MARK: -9.拿到需要的数据，写入外设
    /**
     -- peripheral调用readValueForCharacteristic成功后会回调该方法
     -- peripheral调用setNotifyValue后，特征发出通知也会调用该方法
     */
    // MARK: 获取外设发来的数据
    // 注意，所有的，不管是 read , notify 的特征的值都是在这里读取
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // 写数据，第一个参数转data类型的数据，第二个参数传写入数据的特征，第三个参数是枚举类型分别是CBCharacteristicWriteWithResponse和                                                  CBCharacteristicWriteWithoutResponse；
        //        peripheral.writeValue(T##data: Data##Data, for: <#T##CBCharacteristic#>, type: <#T##CBCharacteristicWriteType#>)
        if let _ = error {
            return
        }
        
        //拿到设备发送过来的值,传出去并进行处理
        if let dataBlock = backDataBlock, let data = characteristic.value {
            dataBlock(data)
        }
    }
    
    // 对于以上的枚举类型的第一个CBCharacteristicWriteWithResponse，每往硬件写入一次数据就会调用一下代理方法
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("\(#function)\n发送数据失败！错误信息：\(error)")
        }
    }
    
    
    //订阅通知的回调
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

