// This script was taken from: https://gist.github.com/eai04191/111b972bf6354a07a984098c4658b18f
//
// シミュレーターのハードウェアキーボードの接続を切り替え、ソフトウェアキーボードを出す・出さないを決める。
// simctlとdevicectlにはこの操作がないため、CoreSimulatorの非公開API（SimDeviceのsetHardwareKeyboardEnabled:keyboardType:error:）を呼ぶ。
// GUIでは、Device Hubの「Simulate hardware keyboard」やClaude Codeのシミュレーターのパネルの「オンスクリーンキーボードを表示」で切り替える。
// Xcodeの更新で名前や型が変わると動かなくなる。そのときは型を確かめて失敗させる。
// 使い方: swift sim-keyboard.swift '<端末の名前またはUDID>' software|hardware

import Foundation
import ObjectiveC

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("sim-keyboard: \(message)\n".utf8))
    exit(1)
}

func developerDir() -> String {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
    process.arguments = ["-p"]
    process.standardOutput = pipe
    do {
        try process.run()
    } catch {
        fail("xcode-selectを実行できない: \(error)")
    }
    process.waitUntilExit()
    let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// 型が想定どおりのときだけ実装を取り出す。Xcodeの更新で型が変わったまま呼ぶと、引数を取り違えて不定の動作になるため
func implementation(of method: Method?, expecting encoding: String, name: String) -> IMP {
    guard let method, let types = method_getTypeEncoding(method) else {
        fail("\(name)が見つからない")
    }
    let actual = String(cString: types)
    guard actual == encoding else {
        fail("\(name)の型が想定と違う（想定: \(encoding)、実際: \(actual)）")
    }
    return method_getImplementation(method)
}

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count == 2, let target = arguments.first, let mode = arguments.last else {
    fail("使い方: swift sim-keyboard.swift '<端末の名前またはUDID>' software|hardware")
}
let hardwareKeyboardEnabled: Bool
switch mode {
case "software": hardwareKeyboardEnabled = false
case "hardware": hardwareKeyboardEnabled = true
default: fail("2つ目の引数はsoftwareかhardware: \(mode)")
}

guard dlopen("/Library/Developer/PrivateFrameworks/CoreSimulator.framework/CoreSimulator", RTLD_NOW) != nil else {
    fail("CoreSimulatorを読み込めない")
}
guard let contextClass = NSClassFromString("SimServiceContext"), let deviceClass = NSClassFromString("SimDevice") else {
    fail("SimServiceContextかSimDeviceが見つからない")
}

typealias SharedContext = @convention(c) (AnyClass, Selector, NSString, AutoreleasingUnsafeMutablePointer<NSError?>) -> NSObject?
typealias DefaultDeviceSet = @convention(c) (NSObject, Selector, AutoreleasingUnsafeMutablePointer<NSError?>) -> NSObject?
typealias SetHardwareKeyboard = @convention(c) (NSObject, Selector, ObjCBool, UInt8, AutoreleasingUnsafeMutablePointer<NSError?>) -> ObjCBool

let sharedSelector = NSSelectorFromString("sharedServiceContextForDeveloperDir:error:")
let deviceSetSelector = NSSelectorFromString("defaultDeviceSetWithError:")
let keyboardSelector = NSSelectorFromString("setHardwareKeyboardEnabled:keyboardType:error:")

let sharedContext = unsafeBitCast(
    implementation(of: class_getClassMethod(contextClass, sharedSelector), expecting: "@32@0:8@16^@24", name: "sharedServiceContextForDeveloperDir:error:"),
    to: SharedContext.self
)
let defaultDeviceSet = unsafeBitCast(
    implementation(of: class_getInstanceMethod(contextClass, deviceSetSelector), expecting: "@24@0:8^@16", name: "defaultDeviceSetWithError:"),
    to: DefaultDeviceSet.self
)
let setHardwareKeyboard = unsafeBitCast(
    implementation(of: class_getInstanceMethod(deviceClass, keyboardSelector), expecting: "B32@0:8B16C20^@24", name: "setHardwareKeyboardEnabled:keyboardType:error:"),
    to: SetHardwareKeyboard.self
)

var error: NSError?
guard let context = sharedContext(contextClass, sharedSelector, developerDir() as NSString, &error) else {
    fail("SimServiceContextを作れない: \(String(describing: error))")
}
guard let deviceSet = defaultDeviceSet(context, deviceSetSelector, &error) else {
    fail("端末の一覧を読めない: \(String(describing: error))")
}
guard let devices = deviceSet.value(forKey: "devices") as? [NSObject] else {
    fail("端末の一覧の形が想定と違う")
}
let matches = devices.filter { device in
    let name = device.value(forKey: "name") as? String
    let udid = (device.value(forKey: "UDID") as? NSUUID)?.uuidString
    return name == target || udid == target
}
guard matches.count == 1, let device = matches.first else {
    fail("'\(target)'に当たる端末が\(matches.count)台ある。1台に決まる名前かUDIDを指定する")
}

// keyboardTypeは0を渡す。0以外の値の意味は調べていない
guard setHardwareKeyboard(device, keyboardSelector, ObjCBool(hardwareKeyboardEnabled), 0, &error).boolValue else {
    fail("切り替えに失敗した: \(String(describing: error))")
}
print("\(target): \(hardwareKeyboardEnabled ? "ハードウェアキーボードをつないだ（ソフトウェアキーボードは出ない）" : "ハードウェアキーボードを外した（ソフトウェアキーボードが出る）")")
