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
//    @State var showResultsView = false
    @State var canVote = false
    @State var startDate = ""
    @State var closeDate = ""
    @State var timeLeft = ""
//    @State var closed = false
//    @State var voteResults = [NSArray]()
    @State var voteResults : NSArray = []
    @State var canViewResults = false
    @State private var showCommentsView = false


    let api = NCAPIController()

    
    func castVote(selected: String) {
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
       
        
//        if expireTime > 0 && now < expireTime {
        if expireTime > 0 {
            self.option = selected

            api.setVote(Int(poll.pollID) as NSNumber, withValue: selected, forUser: account) { response, error in
                print("castVote..: \(String(describing: response))")
                if(error != nil){
                    print("castVoteError: \(String(describing: error))")
                }
            }.resume()
            
        }else{
            print("Voting not started")
        }
        
//        if expireTime > 0 && now > expireTime {
//            self.closed = true
//        }
        
    }
    
    
    
    func getStartTime() {
//        let date = Date()
//            .adding(hours: 3)
//        let now = TimeInterval(date.timeIntervalSince1970)
        let openingTime = TimeInterval(poll.openingTime)
//        let expireTime = TimeInterval(pollStream!.pollExpire)
        let myDate = NSDate(timeIntervalSince1970: openingTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm a"
        let strDate = dateFormatter.string(from: myDate as Date)

//        if expireTime > 0 && now > expireTime {
//            self.closed = true
//        }
        
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
         
//        print("====timer listener=====")
//        print(closing)
//        print(pollStream?.pollExpired ?? false)
        
//        if closing > 0 && pollStream?.pollExpired ?? false {
        if closing > 0 {
            let calendar = Calendar.current
            let now = Date()
//                .adding(hours: 3)
            let date = Date(timeIntervalSince1970: TimeInterval(closing))
//                .adding(hours: 3)
            let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: date)
            if diff.second! >= 0 {
                self.timeLeft = "\(diff.minute!):\(diff.second!)"
            }
//            print("Closing...:\(diff.minute!):\(diff.second!)")
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
                    
            if response != nil {
 
                optionsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                       
                      let option: PollOption = try!  JSONDecoder().decode(PollOption.self, from: jsonData)
                                                                                         
                    pollOptions.append(option)
                 }
                
                print(pollOptions.count)
            
                
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
                               
                      print(".........")
                      print("title....: \(poll.title)")
                      print("openingTime....: \(poll.openingTime)")
                      print("now....: \(now)")
                      print(".........")

                      if poll.meetingID == meetingId && TimeInterval(poll.openingTime) > now {
                          self.pollStream = poll
                        
                          print("PollExpire....: \(poll.title)")
                          print("PollExpire....: \(TimeInterval(poll.pollExpire))")
                          print("Now...........: \(now)")
                          
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
            ResultsView(poll: self.poll, meetingId: self.meetingId)
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
                    
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (Timer) in
                        // listen to poll changes
                        self.listeningPolls()
                        // get closing date
                        self.getCloseDateTime()
                        // get vote results
                        self.getVoteResult()
                    }
                    
                }
                
                VStack{
                    
                    ForEach(pollOptions, id: \.id) { value in
                        RadioButtonField(
                            id: "\(value.id)",
                            label: "\(value.pollOptionText)",
                            bgColor: $option.wrappedValue == "\(value.id)" ? .green : .red,
                            isMarked: $option.wrappedValue == "\(value.id)" ? true : false,
                            callback: { selected in
                                self.castVote(selected: selected)
                                print("Selected vote is: \(selected)")
                            }
                        ).padding()
                    }
                    
                }.onAppear(){
                    // poll options
                    self.getPollOptions()
                }
                
                VStack{
                    Text("Members who have voted: \(voteResults.count)")
//                    Text("Total verified voters: 2...")
                        .padding()
                }

            }.padding()
            .navigationBarItems(
                trailing: HStack {
                    NavigationLink(destination: CommentsView(), isActive: $showCommentsView) { EmptyView() }
                    Button("Comments") {
                        self.showCommentsView = true
                    }
                }
            )
        }
            
        
//       if pollStream?.pollExpired ?? false {
//           // check if voting time is done
////            ResultsView(closeDate: poll.pollID, poll:closeDate, meetingId: self.meetingId, voteResults: pollOptions)
//           ResultsView(poll: self.poll, meetingId: self.meetingId)
//               .onAppear {
//                   print("ResultsView...")
//               print("\( poll.pollID)")
//               print("\( poll.title)")
//               print("\( poll.meetingID)")
//           }
//       }
//       if pollStream != nil {
//           NavigationLink(destination: ResultsView(poll: self.poll, meetingId: self.meetingId),
//                          isActive:self.$canViewResults ) {
//                EmptyView()
//           }.hidden()
//       }
    }
}

@available(iOS 14.0, *)
struct VotingView_Previews: PreviewProvider {
    static var previews: some View {
//        VotingView()
        EmptyView()
    }
}

