//
//  ResultsView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 06/01/2022.
//

import SwiftUI
import SwiftyJSON

// MARK: - PollResult
struct CombinedResult {
    let id, pollID, order: Int
    let pollOptionText: String
    let voteAnswers: [PollVoteResult]
}

@available(iOS 14.0, *)
struct ResultsView: View {
    
    let api = NCAPIController()
//    let pollId : Int
    @State var poll:Poll
    @State var meetingId : String
    @State var voteResults = [PollVoteResult]()
    @State var pollOptions = [PollOption]()
    @State var combinedResults = [CombinedResult]()
    @State var closeDate = ""


    func getVoteResult() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        
        api.getVotes(account, forPollId: poll.pollID as NSNumber) { response, error in
            
            let resultsArray : NSArray = response?["votes"] as? NSArray ?? []
             
            print("ResultsArray..: \(String(describing: resultsArray))")
                    
            if response != nil {
                
                resultsArray.forEach { resultJson in
                      let json = JSON(resultJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                       
                      let result: PollVoteResult = try!  JSONDecoder().decode(PollVoteResult.self, from: jsonData)
                                             
                      print(result)
                                            
                    voteResults.append(result)
                 }
                
                print("PollResults...:")
                print(voteResults.count)
                
                if(voteResults.count>0){
                    combinedResults = pollOptions.map { option in
                        CombinedResult(id: option.id, pollID: option.pollID, order:option.order, pollOptionText: option.pollOptionText, voteAnswers: voteResults.compactMap { $0.id == option.id ? $0.with(id: $0.id, pollID: $0.pollID, userID: $0.userID, voteOptionID: $0.voteOptionID, voteOptionText: $0.voteOptionText, voteAnswer: $0.voteAnswer, isNoUser: $0.isNoUser, displayName: $0.displayName) : nil})
                    }
                }
                
                print("CombinedResults...:")
                print(combinedResults.count)

            }else{
                print("No results")
            }
            
            if(error != nil){
                print("getVoteResultError: \(String(describing: error))")
            }
        }.resume()
    }
    
    func getPolls() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()

        // get polls
        api.getPolls(account) { response, error in
            
            let pollsArray : NSArray = response?["polls"] as? NSArray ?? []
                                 
            if response != nil {
                
                  pollsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                      let poll: Poll = try!  JSONDecoder().decode(Poll.self, from: jsonData)
                                             
                      print(poll.title)
                     
                      if poll.meetingID == meetingId {
//                          self.loading = false
                          print("======LETS POLL VOTE====")
                          self.poll = poll
//                          print("Poll..: \(String(describing: self.poll))")
                      }
                      
                 }
                                
            }else{
                print("No results")
                
            }
            
            
            if(error != nil){
                print("Error: \(String(describing: error))")
            }

        }.resume()
        
        
    }
    
    func getCloseDateTime() {
        
        let closing = poll.pollExpire;
        let expireTime = TimeInterval(closing)
        let myDate = NSDate(timeIntervalSince1970: expireTime)
         
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm a"
        let strDate = dateFormatter.string(from: myDate as Date)
        
        self.closeDate = strDate
        
    }
    
    var body: some View {
        
        VStack(spacing:70){
            
            VStack{
                
                Text("\(poll.title)")
                    .fontWeight(.bold)
                
                Text("Closed on \(closeDate)")
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)

            }.padding()
            .onAppear(){
                self.getVoteResult()
                self.getCloseDateTime()
            }
               
            
            VStack{
                
                if  voteResults.count > 0 {
                    ForEach(combinedResults, id: \.id) { value in
                        let total = Double(voteResults.count)
                        let percentage = Double(value.voteAnswers.count)/total*100

                        HStack {
                            Text("\(value.pollOptionText)")
                            Spacer()
                            Text("\(percentage)%")
                                .padding()
                            Text("\(value.voteAnswers.count)")
                        }
                    }
                    
                } else {
                    ForEach(combinedResults, id: \.id) { value in
                        let total = Double(voteResults.count)
                        let percentage = Double(value.voteAnswers.count)/total*100

                        HStack {
                            Text("\(value.pollOptionText)")
                            Spacer()
                            Text("\(percentage)%")
                                .padding()
                            Text("\(value.voteAnswers.count)")
                        }
                    }
                    
                }
                
                ForEach(pollOptions, id: \.id) { value in
                    
                    HStack {
                        Text("\(value.pollOptionText)")
                        Spacer()
                        Text("0%")
                            .padding()
                        Text("0")
                    }
                }
                
            }
                        
            VStack{
              if  voteResults.count > 0 { Text("TOTAL VOTES:  100%") } else { Text("TOTAL VOTES:  0%") }
                Text("Members who have voted: \(voteResults.count)")
                    .padding()
//                Text("Total verified voters: 2")
            }

        }.padding()
    
    }
}

@available(iOS 14.0, *)
struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
