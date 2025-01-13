import Foundation

public class CustomAction {
    var action: String
    var param: [String: Any] = [:]
    
    init(action: String) {
        self.action = action
    }
    
    func getAction() -> String {
        return action
    }
    
    func getParam() -> [String: Any] {
        return param
    }
}
