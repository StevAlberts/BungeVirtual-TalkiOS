//
//  VotingAPI.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 28/12/2021.
//

import Foundation

struct Vote: Codable, Identifiable {
    var id = UUID()
    var author: String
    var email: String
    var title: String
}


@available(iOS 13.0, *)
class VotingAPI : ObservableObject{
    @Published var votes = [Vote]()
    
    var pollsURL = "https://bungevirtual.com/apps/polls/api/v1.0/polls";
    
    func loadData(completion:@escaping ([Vote]) -> ()) {
        guard let url = URL(string: pollsURL) else {
            print("Invalid url...")
            return
        }
        
        let account = TalkAccount()
        let room = NCRoom()
        
        print("Values are here")
        print(account.userId)
        print(room.token!)

        
        URLSession.shared.dataTask(with: url) { data, response, error in
            let votes = try! JSONDecoder().decode([Vote].self, from: data!)
            print(votes)
            DispatchQueue.main.async {
                completion(votes)
            }
        }.resume()
        
    }
    
    func pollsData() {
        // user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()

        let api = NCAPIController()
        
        print("Values are here:")
        print(account.userId)
               

//        api.getPolls(account, withCompletionBlock: { <#[AnyHashable : Any]?#>, <#Error?#> in
            
//        }).resume()
        
    }
    
//    func signIn() {
//
//
//        var request = URLRequest(url: URL(string: "http://localhost:8080/api/v1/signin")!)
//
//        request.httpMethod = "POST"
//
//        var account = TalkAccount()
//        var room = NCRoom()
//
//
//        let authData = (email + ":" + password).data(using: .utf8)!.base64EncodedString()
//
//        request.addValue("Basic \(authData)", forHTTPHeaderField: "Authorization")
//
//        isSigningIn = true
//
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            DispatchQueue.main.async {
//                if error != nil || (response as! HTTPURLResponse).statusCode != 200 {
//                    self?.hasError = true
//                } else if let data = data {
//                    do {
//                        let signInResponse = try JSONDecoder().decode(SignInResponse.self, from: data)
//
//                        print(signInResponse)
//
//                        // TODO: Cache Access Token in Keychain
//                    } catch {
//                        print("Unable to Decode Response \(error)")
//                    }
//                }
//
//                self?.isSigningIn = false
//            }
//        }.resume()
//    }
}
