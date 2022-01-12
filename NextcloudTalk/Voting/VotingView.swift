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
     
//    @State var polls = []
    
    @State var pollOptions = [PollOption]()
    
    @State var poll:Poll

    @State var option = ""
    @State var showResultsView = false
    @State var canVote = false

    @State var startDate = ""
    
    @State var closeDate = ""
    
    @State var closed = false

    let api = NCAPIController()


    
    func castVote(selected: String) {
        
//        let date = NSDate() // current date
        let date = Date()
//            .adding(hours: 3)
        let now = date.timeIntervalSince1970
        let openingTime = TimeInterval(poll.openingTime)
         
//        showResults()
        print("Voted: \(option)\nNow: \(now)\nOpening: \(openingTime)")
        
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        
        if poll.allowVote {
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
        
    }
    
    func showResults() {
            self.showResultsView = true
    }
    
    func getStartTime() {
//        print(poll)
        let date = Date()
            .adding(hours: 3)
        let now = TimeInterval(date.timeIntervalSince1970)
        
        let openingTime = TimeInterval(poll.openingTime)
//        let expireTime = TimeInterval(poll.pollExpire)
        
        let myDate = NSDate(timeIntervalSince1970: openingTime)
        
        let myDatenow = NSDate(timeIntervalSince1970: now)

        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy HH:mm a"
        let strDate = dateFormatter.string(from: myDate as Date)
        
        let strDate2 = dateFormatter.string(from: myDatenow as Date)

        print("Date..: \(strDate)")
        print("Dates..: \(strDate2)")

        print("now..: \(now)")
        print("openingTime..: \(openingTime)")

        if now > openingTime {
            self.closed = true
        }
        
        self.startDate = strDate
    }
    
    func getPollOptions() {
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
                                             
//                      print(option)
                                            
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

    var body: some View {
        
        if showResultsView {
            ResultsView()
        }else{
            VStack(spacing:70){
                 
                VStack{
                    Text("\(poll.title)")
                        .fontWeight(.bold)
                    
//                    if closed {
//                        Text("Closed on \(startDate)")
//                            .foregroundColor(Color.red)
//                            .multilineTextAlignment(.center)

//                    } else {
                        Text("The vote is expected to start on \(startDate)")
                            .fontWeight(.light)
                            .multilineTextAlignment(.center)
//                    }
                    
//                    else if poll.allowVote {
//
//                       Text("Closing in \(closeDate)")
//                           .foregroundColor(Color.orange)
//                           .multilineTextAlignment(.center)
//
//                   }
                    
                    
                    
                }.onAppear {
                    
                    self.getStartTime()
                    self.getPollOptions()
                    
                    print("VotingView: \(String(describing: poll))")
                    
                    var secondsRemaining = poll.pollExpire;
                    
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (Timer) in
                        if secondsRemaining > 0 {
                            print ("\(String(describing: secondsRemaining)) seconds")
                            self.closeDate = String(secondsRemaining)
                            secondsRemaining -= 1
                        } else {
                            Timer.invalidate()
                        }
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
                                print("Selected Gender is: \(selected)")
                            }
                        ).padding()
                    }
                    
                }
                
                VStack{
                    Text("Members who have voted: 1...")
                    Text("Total verified voters: 2...")
                        .padding()
                }

            }.padding()
            
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

