import Foundation

enum BuildConfiguration {
    #if REBRICKABLE_API_KEY_INJECTED
    static let rebrickableAPIKey: String = REBRICKABLE_API_KEY
    #else
    static let rebrickableAPIKey: String? = nil
    #endif
    
    static var hasEmbeddedAPIKey: Bool {
        #if REBRICKABLE_API_KEY_INJECTED
        return !rebrickableAPIKey.isEmpty
        #else
        return false
        #endif
    }
}