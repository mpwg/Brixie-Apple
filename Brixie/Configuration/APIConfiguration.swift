import Foundation

struct APIConfiguration {
    // Read API key from Info.plist - this gets populated from REBRICKABLE_API_KEY environment variable
    private static let embeddedKey: String? = Bundle.main.infoDictionary?["REBRICKABLE_API_KEY"] as? String
    
    static let rebrickableAPIKey: String? = embeddedKey
    static let hasEmbeddedAPIKey: Bool = embeddedKey != nil && !embeddedKey!.isEmpty
    static let buildDate = Date()
}
