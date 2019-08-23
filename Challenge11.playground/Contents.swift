import UIKit

enum Errors: Error {
    case invalidData
    case failedToRetrieveRemoteData
}

var testJsonString = """
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
//guard let jsonData = testJsonString(using: .utf8) else { throw Errors.invalidData }

struct Pubs: Decodable {
    let pubs: [Pub]
    
    enum CodingKeys: String, CodingKey {
        case pubs = "Pubs"
    }
}

extension Pubs {
    func listUniquePubs(pubs: [Pub]) -> [Pub] {
        var filteredPubs: [Pub] = []
        var pubs = pubs
        
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
        
        return filteredPubs
    }
    
    func listAllUniqueBeers(pubs: [Pub]) -> [String] {
        var beers: [String: Bool] = [:]
        
        for pub in pubs {
            pub.regularBeers?.map { beers[$0] = true }
            pub.guestBeers?.map { beers[$0] = true }
        }
        
        return Array(beers.keys)
    }
    
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

func obtainListOfBeers(jsonData: Data) throws -> [String] {
    let pubs = try Pubs.decode(from: jsonData)
    return pubs.listAllUniqueBeers(pubs: pubs.pubs).sorted()
}

print(try obtainListOfBeers(jsonData: jsonData))
print("\n")
do {
    let pubs = try Pubs.decode(from: jsonData)
    let allPubsCount = pubs.pubs.count
    let uniquePubsCount = pubs.listUniquePubs(pubs: pubs.pubs).count
    print("Total pubs: \(allPubsCount), unique pubs: \(uniquePubsCount)")
} catch {
    print("\(error)")
}

