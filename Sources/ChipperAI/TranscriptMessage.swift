import Foundation

public extension String {
    static let speakerOwnerID: String = UUID().uuidString
    static let listenerOwnerID: String = UUID().uuidString
}

public struct TranscriptMessage: Identifiable, Hashable {
    
    public enum Content: Hashable {
        case text(String)
        case media(URL)
    }
    
    public let id: UUID
    public let ownerID: String
    public let content: Content
    public let date: Date
    
    public init(
        id: UUID = UUID(),
        ownerID: String = UUID().uuidString,
        content: Content,
        date: Date = Date()
    ){
        self.id = id
        self.ownerID = ownerID
        self.content = content
        self.date = date
    }
}


public extension Collection where Element == TranscriptMessage {
    
    func groupByOwnerIDInTimeWindow(seconds interval: TimeInterval) -> [[Element]] {
        guard !isEmpty else { return [] }
        
        let sortedByDate = sorted(by: { $0.date < $1.date })
        var result: [[Element]] = [[]]
        var groupIndex = 0
        
        for item in sortedByDate {
            if let first = result[groupIndex].first {
                let dateWindow = item.date.timeIntervalSince(first.date)
                if first.ownerID == item.ownerID && dateWindow < interval {
                    result[groupIndex].append(item)
                } else {
                    groupIndex += 1
                    result.append([item])
                }
            } else {
                result[groupIndex].append(item)
            }
        }
        
        return result
    }
    
}
