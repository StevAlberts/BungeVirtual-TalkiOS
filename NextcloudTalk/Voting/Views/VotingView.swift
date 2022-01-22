//
//  VotingView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 06/01/2022.
//
 
import SwiftUI
import SwiftyJSON

@available(iOS 14.0, *)
struct VotingView: View {
         
    @State var pollOptions = [PollOption]()
    @State var poll:Poll
    @State var pollStream:Poll?
    @State var meetingId : String
    @State var option = ""
    @State var optionLast = ""
    @State var optionIDLast = 0
    @State var canVote = false
    @State var startDate = ""
    @State var closeDate = ""
    @State var timeLeft = ""
    @State var voteResults : NSArray = []
    @State private var shares = 0
    @State var canViewResults = false
    @State private var showCommentsView = false
    @State private var hasPolls = false
    @State private var startVote = false

    let api = NCAPIController()
    
    
    func setVote(optionId: Int,selected: String) {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        
//        let date = NSDate() // current date
        let date = Date()
//            .adding(hours: 3)
        let now = date.timeIntervalSince1970
        
        let expireTime = TimeInterval(pollStream?.pollExpire ?? 0)
         
//        showResults()
        print("Voted: \(option) Now: \(now) Opening: \(expireTime)")
       
//        if timeLeft != "" {}
        
//        if expireTime > 0 && now < expireTime {
        self.option = "\(optionId)"

        if expireTime > 0 {
            print("Voting started.....:\(selected)")
            if self.optionLast == "" {
                self.optionLast = self.option
                self.optionIDLast = optionId
                api.setVote(optionId as NSNumber, withValue: "yes", forUser: account) { response, error in
                    print("castVote..: \(String(describing: response))")
                    if(error != nil){
                        print("castVoteError: \(String(describing: error))")
                    }
                }.resume()
            }else{
                api.setVote(optionIDLast as NSNumber, withValue: "", forUser: account) { response, error in
                    print("castVoteDelete..: \(String(describing: response))")
                   
                    if(error != nil){
                        print("castVoteError: \(String(describing: error))")
                    }else{
                        self.optionLast = self.option
                        self.optionIDLast = optionId
                        api.setVote(optionId as NSNumber, withValue: "yes", forUser: account) { response, error in
                            print("castVoteSet..: \(String(describing: response))")
                            if(error != nil){
                                print("castVoteError: \(String(describing: error))")
                            }
                        }.resume()
                    }
                }.resume()
                
            }
          
        }else{
            print("Voting not started......")
        }
        
    }
    
    
    
    func getStartTime() {
        let openingTime = TimeInterval(poll.openingTime)
        let myDate = NSDate(timeIntervalSince1970: openingTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm a"
        let strDate = dateFormatter.string(from: myDate as Date)
        
        self.startDate = strDate
    }
    
    func getCloseDateTime() {
        
        let closing = pollStream?.pollExpire ?? 0;
        let expireTime = TimeInterval(closing)
        let myDate = NSDate(timeIntervalSince1970: expireTime)
         
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm a"
        let strDate = dateFormatter.string(from: myDate as Date)
        
        self.closeDate = strDate
         
        if closing > 0 {
            let calendar = Calendar.current
            let now = Date()
            let date = Date(timeIntervalSince1970: TimeInterval(closing))
//                .adding(hours: 3)
            let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: date)
            if diff.second! >= 0 {
                let mins = String(format: "%02d", diff.minute!)
                let secs = String(format: "%02d", diff.second!) // returns "100"
                self.timeLeft = "\(mins):\(secs)"
            }
        }
    }
    
    func getPollOptions() {
        print("====================getPollOptions============================")
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
                   
        api.getPollOptions(account, forPollId: Int(poll.pollID) as NSNumber) { response, error in
            
            let optionsArray : NSArray = response?["options"] as? NSArray ?? []
             
            print("OptionsArray..: \(String(describing: optionsArray))")
                    
            var allOptions = [PollOption]()

            if response != nil {
 
                optionsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                       
                      let option: PollOption = try!  JSONDecoder().decode(PollOption.self, from: jsonData)
                                                                                         
                    allOptions.append(option)
                 }
                
                pollOptions = allOptions
                
                print("Has polls...:\(pollOptions.count)")
                
                if pollOptions.count>0{
                    self.hasPolls = true
                }
            
                
            }else{
                print("No results")
            }
            
            if(error != nil){
                print("Error: \(String(describing: error))")
            }
        }.resume()
    }
    
    func listeningPolls() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        let date = Date()
//            .adding(hours: 3)
        let now = TimeInterval(date.timeIntervalSince1970)
        
        // get polls
        api.getPolls(account) { response, error in
                                
            let pollsArray : NSArray = response?["polls"] as? NSArray ?? []
                                 
            if response != nil {
                
                  pollsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                      
                      let poll: Poll = try!  JSONDecoder().decode(Poll.self, from: jsonData)
                               
//                      print(".........")
//                      print("title....: \(poll.title)")
//                      print("openingTime....: \(poll.openingTime)")
//                      print("now....: \(now)")
                      print("Poll stream.......:\(poll)")

                      if poll.meetingID == meetingId && TimeInterval(poll.openingTime) > now {
                          self.pollStream = poll
                          
                          if poll.pollExpire > 0 {
                              self.startVote = true
                          }
                        
//                          print("Title....: \(poll.title)")
//                          print("PollExpire....: \(TimeInterval(poll.pollExpire))")
//                          print("Now...........: \(now)")
                          
                          self.canViewResults = poll.pollExpired

//                          if TimeInterval(poll.pollExpire) > 0 && TimeInterval(poll.pollExpire) < now {
//                              self.canViewResults = poll.pollExpired
//                              print("Can View ....: \(canViewResults)")
//                          }
                         
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
    
    func listeningShares() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        
        // get polls
        api.getShares(account, forPollId: Int(poll.pollID) as NSNumber) { response, error in
                                
            let sharesArray : NSArray = response?["shares"] as? NSArray ?? []
                                 
            if response != nil {
                
                print("Shares....:\(sharesArray.count)")
                
                self.shares = sharesArray.count
                
            }else{
                print("No results")
            }
            
            if(error != nil){
                print("Error: \(String(describing: error))")
            }

        }.resume()
        
    }
    
    func getVoteResult() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        
        api.getVotes(account, forPollId: poll.pollID as NSNumber) { response, error in
            
            let resultsArray : NSArray = response?["votes"] as? NSArray ?? []
             
//            print("ResultsArray..: \(String(describing: resultsArray))")
                    
            if response != nil {
                
//                resultsArray.forEach { resultJson in
//                      let json = JSON(resultJson).rawString()
//                      let jsonData = json!.data(using: .utf8)!
//
//                      let result: PollVoteResult = try!  JSONDecoder().decode(PollVoteResult.self, from: jsonData)
//
//                      print(result)
//
//                    voteResults.append(result)
//                 }
                
                voteResults = resultsArray
                
                print("PollResults...:\(voteResults.count)")

            }else{
                print("No results")
            }
            
            if(error != nil){
                print("getVoteResultError: \(String(describing: error))")
            }
        }.resume()
    }

    var body: some View {
        
        if canViewResults {
            // show vote results when voting is done
            ResultsView(poll: self.poll, meetingId: self.meetingId, shares: self.shares, pollOptions: pollOptions)
        } else {
            VStack(spacing:70){
                 
                VStack{
                    Text("\(poll.title)")
                        .fontWeight(.bold)
                                             
                    
//                    if poll.pollExpired {
//                        Text("Closed on \(startDate)")
//                            .foregroundColor(Color.red)
//                            .multilineTextAlignment(.center)
//                    } else
                    if timeLeft != "" {
                        Text("Closing in \(timeLeft)")
                            .foregroundColor(Color.orange)
                            .multilineTextAlignment(.center)

                    } else {
                        Text("The vote is expected to start on \(startDate)")
                            .fontWeight(.light)
                            .multilineTextAlignment(.center)
                    }
                    
                }.onAppear {
                    
                    self.getStartTime()
                    
                    print("VotingView: \(String(describing: poll))")
                    
                    // poll options
                    self.getPollOptions()
                    
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (Timer) in
                        // listen to poll changes
                        self.listeningPolls()
                        // listen to shares
                        self.listeningShares()
                        // get closing date
                        self.getCloseDateTime()
                        // get vote results
                        self.getVoteResult()
                    }
                    
                }
                
                if hasPolls {
                    VStack{
                        ForEach(pollOptions, id: \.id) { value in
                            RadioButtonField(
                                id: "\(value.id)",
                                label: "\(value.pollOptionText)",
                                bgColor: $option.wrappedValue == "\(value.id)" ? .green : .red,
                                isMarked: $option.wrappedValue == "\(value.id)" ? true : false,
                                callback: { selected in
                                    self.option = "\(selected)"
                                    self.setVote(optionId: Int(selected)!,selected: value.pollOptionText.lowercased())
                                    print("Selected...: \(selected)")
                                    print("Option...: \(value.id)")

                                }
                            ).padding()
                            .disabled(startVote == false)

                        }
                        
                    }
                }else{
                    ProgressView()
                        .scaleEffect(2.0)
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                VStack{
                    Text("Members who have voted: \(voteResults.count)")
                    Text("Total verified voters: \(shares)")
                        .padding(2)
                }

            }.padding()
                
//            .navigationBarItems(
//                trailing: HStack {
//                    NavigationLink(destination: CommentsView(pollId: poll.pollID), isActive: $showCommentsView) { EmptyView() }
//                    Button("Comments") {
//                        self.showCommentsView = true
//                    }
//                }
//            )
        }
    }
}

@available(iOS 14.0, *)
struct VotingView_Previews: PreviewProvider {
    static var previews: some View {
//        VotingView()
        EmptyView()
    }
}

