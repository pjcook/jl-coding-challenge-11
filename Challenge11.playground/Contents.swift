import UIKit

enum Errors: Error {
    case invalidData
    case failedToRetrieveRemoteData
}

let testJsonString = """
{
   "Pubs":[
      {
         "Name":"Cask and Glass",
         "PostCode":"SW1E 5HN",
         "RegularBeers":[
            "Shepherd Neame Master Brew",
            "Shepherd Neame Spitfire"
         ],
         "GuestBeers":[
            "Shepherd Neame --seasonal--",
            "Shepherd Neame --varies--",
            "Shepherd Neame Whitstable Bay Pale Ale"
         ],
         "PubService":"https://pubcrawlapi.appspot.com/pub/?v=1&id=15938&branch=WLD&uId=mike&pubs=no&realAle=yes&memberDiscount=no&town=London",
         "Id":"15938",
         "Branch":"WLD",
         "CreateTS":"2019-05-16 19:31:39"
      }
   ]
}
"""

guard let jsonData = try? Data(contentsOf: URL(string: "https://pubcrawlapi.appspot.com/pubcache/?uId=mike&lng=-0.141499&lat=51.496466&deg=0.003")!) else { throw Errors.failedToRetrieveRemoteData }
//guard let jsonData = testJsonString.data(using: .utf8) else { throw Errors.invalidData }

struct Pubs: Decodable {
    let pubs: [Pub]
    
    enum CodingKeys: String, CodingKey {
        case pubs = "Pubs"
    }
}

extension Pubs {
    /// This will return a unique list of pubs filtering pubs using "uniqueID" and selecting the unique pub with the most recent created date
    var uniquePubs: [Pub] {
//        let createdAt = Date()
        var filteredPubs: [Pub] = []
        var pubs = self.pubs
        
        while !pubs.isEmpty {
            let pub = pubs.removeFirst()
            if pubs.isEmpty {
                filteredPubs.append(pub)
                continue
            }
            
            var newest = pub
            for p in pubs where p.uniqueID == pub.uniqueID {
                if p.createdTimestamp > newest.createdTimestamp {
                    newest = p
                }
            }
            pubs.removeAll { $0.uniqueID == newest.uniqueID }
            filteredPubs.append(newest)
        }
        
//        print("A:\(createdAt.timeIntervalSinceNow)")
        return filteredPubs
    }
    
    /// Alternative filtering algorithm
    /// This will return a unique list of pubs filtering pubs using "uniqueID" and selecting the unique pub with the most recent created date
    var uniquePubs2: [Pub] {
//        let createdAt = Date()
        var filteredPubs: [Pub] = []
        let pubs = self.pubs.sorted { $0.uniqueID < $1.uniqueID }
        var index = 0
        
        while index < pubs.count {
            var pub = pubs[index]
            index += 1
            if index >= pubs.count {
                filteredPubs.append(pub)
                break
            }
            
            while index < pubs.count, pub.uniqueID == pubs[index].uniqueID {
                if pubs[index].createdTimestamp > pub.createdTimestamp {
                    pub = pubs[index]
                }
                index += 1
            }
            filteredPubs.append(pub)
        }
//        print("B:\(createdAt.timeIntervalSinceNow)")
        return filteredPubs
    }
    
    /// Unique list of all beers provided by the pubs passed to the function
    ///
    /// - Parameter pubs: list of pubs to return unique list of beers for
    /// - Returns: unique list of beers unsorted
    func uniqueBeers(pubs: [Pub]) -> [String] {
        var beers: [String: Bool] = [:]
        
        for pub in pubs {
            pub.regularBeers?.map { beers[$0] = true }
            pub.guestBeers?.map { beers[$0] = true }
        }
        
        return Array(beers.keys)
    }
    
    /// Function to convert the JSON DATA into a Pubs model class
    ///
    /// - Parameter jsonData: JSON DATA to parse
    /// - Returns: parsed Pubs class
    /// - Throws: throws if fails to parse the JSON DATA
    static func decode(from jsonData: Data) throws -> Pubs {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try decoder.decode(Pubs.self, from: jsonData)
    }
}

typealias PubID = String

struct Pub: Decodable {
    let name: String
    let postcode: String?
    let regularBeers: [String]?
    let guestBeers: [String]?
    let pubService: String
    let id: PubID
    let branch: String
    let createdTimestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case postcode = "PostCode"
        case regularBeers = "RegularBeers"
        case guestBeers = "GuestBeers"
        case pubService = "PubService"
        case id = "Id"
        case branch = "Branch"
        case createdTimestamp = "CreateTS"
    }
}

extension Pub: Hashable {
    var uniqueID: String { return id + branch }
}

/// create a function called obtainListOfBeers to convert json listing each pub within an area into json listing different types of beer available in the same area
///
/// - Parameter jsonData: Obtain the Json and convert it to DATA
/// - Returns: Unique list of all beers sorted alphabetically
/// - Throws: throws error if it fails to parse the JSON DATA
func obtainListOfBeers(jsonData: Data) throws -> [String] {
    let pubs = try Pubs.decode(from: jsonData)
    return pubs.uniqueBeers(pubs: pubs.pubs).sorted()
}

print(try obtainListOfBeers(jsonData: jsonData))
print("\n")
do {
    let pubs = try Pubs.decode(from: jsonData)
    let allPubsCount = pubs.pubs.count
    let uniquePubsCount = pubs.uniquePubs2.count
    print("Total pubs: \(allPubsCount), unique pubs: \(uniquePubsCount)")
    
    let uniquePubs = pubs.uniquePubs.sorted { $0.name < $1.name }
    let uniquePubs2 = pubs.uniquePubs2.sorted { $0.name < $1.name }
    print("Test algorithms return same results:\(uniquePubs == uniquePubs2)")

} catch {
    print("\(error)")
}
