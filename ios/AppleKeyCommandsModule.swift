import ExpoModulesCore
import UIKit
import ObjectiveC.runtime

public class AppleKeyCommandsModule: Module {
  public func definition() -> ModuleDefinition {
    Name("AppleKeyCommands")
    Events("onKeyCommand")

    Function("isSupported") { () -> Bool in true } // the iOS module only loads on iOS

    Function("setKeyCommands") { (commands: [[String: Any]]) in
      DispatchQueue.main.async {
        KeyCommandCenter.shared.emit = { [weak self] id in self?.sendEvent("onKeyCommand", ["id": id]) }
        KeyCommandCenter.shared.setCommands(commands)
      }
    }
    Function("clearKeyCommands") {
      DispatchQueue.main.async { KeyCommandCenter.shared.setCommands([]) }
    }
  }
}

final class KeyCommandCenter: NSObject {
  static let shared = KeyCommandCenter()
  var emit: ((String) -> Void)?
  private weak var hostVC: UIViewController?
  private var actionInstalled = false

  func setCommands(_ commands: [[String: Any]]) {
    guard let rootVC = Self.keyWindow()?.rootViewController else { return }
    installActionIfNeeded(on: rootVC)

    (hostVC?.keyCommands ?? []).forEach { hostVC?.removeKeyCommand($0) }
    hostVC = rootVC
    let sel = NSSelectorFromString("ak_handleKeyCommand:")
    for c in commands {
      guard let id = c["id"] as? String, let raw = c["input"] as? String else { continue }
      var mods: UIKeyModifierFlags = []
      for m in (c["modifiers"] as? [String] ?? []) {
        switch m {
        case "command": mods.insert(.command); case "shift": mods.insert(.shift)
        case "option": mods.insert(.alternate); case "control": mods.insert(.control); default: break
        }
      }
      let cmd = UIKeyCommand(title: (c["title"] as? String) ?? "", image: nil, action: sel,
                             input: Self.mapInput(raw), modifierFlags: mods, propertyList: id)
      rootVC.addKeyCommand(cmd)
    }
  }

  private func installActionIfNeeded(on vc: UIViewController) {
    guard !actionInstalled else { return }
    actionInstalled = true
    let sel = NSSelectorFromString("ak_handleKeyCommand:")
    let block: @convention(block) (AnyObject, UIKeyCommand) -> Void = { _, cmd in
      if let id = cmd.propertyList as? String { KeyCommandCenter.shared.emit?(id) }
    }
    let imp = imp_implementationWithBlock(block)
    class_addMethod(type(of: vc), sel, imp, "v@:@")
  }

  static func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first
  }
  static func mapInput(_ raw: String) -> String {
    switch raw.lowercased() {
    case "return","enter": return "\r"
    case "escape","esc": return UIKeyCommand.inputEscape
    case "space": return " "
    case "tab": return "\t"
    case "up": return UIKeyCommand.inputUpArrow
    case "down": return UIKeyCommand.inputDownArrow
    case "left": return UIKeyCommand.inputLeftArrow
    case "right": return UIKeyCommand.inputRightArrow
    default: return raw
    }
  }
}
