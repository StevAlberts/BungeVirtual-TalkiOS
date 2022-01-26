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
    let voteAnswers: [String]
}

@available(iOS 14.0, *)
struct ResultsView: View {
    
    let api = NCAPIController()
//    let pollId : Int
    @State var poll:Poll
    @State var meetingId : String
    @State var shares : Int
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
            
            var voteArr = [PollVoteResult]()

            if response != nil {
                
                resultsArray.forEach { resultJson in
                      let json = JSON(resultJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                       
                      let result: PollVoteResult = try!  JSONDecoder().decode(PollVoteResult.self, from: jsonData)
                                             
                      print(result)
                                            
                    voteArr.append(result)
                 }
                
                voteResults = voteArr
                
                print("VoteResults...:\(voteResults.count)\nPollOptions...:\(pollOptions.count)")
                                
                if(voteResults.count>0 && pollOptions.count>0){
                    combinedResults = pollOptions.map { option in
                        CombinedResult(id: option.id, pollID: option.pollID, order:option.order, pollOptionText: option.pollOptionText, voteAnswers: voteResults.compactMap {
                            return $0.voteOptionID == option.id ? $0.userID : nil
                        })
                    }
                    
                }
                
                print("CombinedResults...:")
                print(combinedResults.count)
                
                combinedResults.forEach { result in
                    print("CombinedResult...:\(result)")
                }
                

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
                          print("======VOTE RESULTS====")
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
    
    func getPollOptions() {
        print("====================getPollOptions============================")
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
                   
        api.getPollOptions(account, forPollId: Int(poll.pollID) as NSNumber) { response, error in
            
            let optionsArray : NSArray = response?["options"] as? NSArray ?? []
             
//            print("OptionsArray..: \(String(describing: optionsArray))")
                    
            var allOptions = [PollOption]()

            if response != nil {
 
                optionsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                       
                      let option: PollOption = try!  JSONDecoder().decode(PollOption.self, from: jsonData)
                                                                                         
                    allOptions.append(option)
                 }
                
                pollOptions = allOptions
                
//                print(pollOptions.count)
            
                
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
        
        print("Closing.....:\(closing)")
        print("myDate.....:\(myDate)")
        print("CloseDate.....:\(closeDate)")
        
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
//                self.getPolls()
            }
               
            
            VStack{
                
                if  voteResults.count > 0 {
                    
                    ForEach(combinedResults, id: \.id) { value in
                        let total = Double(voteResults.count)
                        let percentage = Int(Double(value.voteAnswers.count)/total*100)
                        
                        HStack {
                            Text("\(value.pollOptionText)")
                            Spacer()
                            Text("\(percentage)%")
                                .padding()
                            Text("\(value.voteAnswers.count)")
                        }.onAppear(){
                            
                            let total = Double(voteResults.count)
                            let percentage = Double(value.voteAnswers.count)/total*100
                            
                            print("Result...(\(value.pollOptionText)):\(value.id)  :\(percentage)%     :\(value.voteAnswers.count)")
                        }
                        
                    }
                    
                } else {
                    ProgressView()
                        .scaleEffect(2.0)
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
            }
                        
            VStack{

              if  voteResults.count > 0 { Text("TOTAL VOTES:  100%") } else { Text("TOTAL VOTES:  0%") }
                Text("Members who have voted: \(voteResults.count)")
                    .padding()
                Text("Total verified voters: \(shares)")
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
