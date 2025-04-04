import Foundation

public class CustomAction {
    var action: String
    var param: [String: Any] = [:]
    
    init(action: String) {
        self.action = action
    }
    
    public func getAction() -> String {
        return action
    }
    
    public func getParam() -> [String: Any] {
        return param
    }
}
