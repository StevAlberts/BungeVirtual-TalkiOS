//
//  CommentsView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 17/01/2022.
//

struct Comments: Hashable {
    let id, pollID: Int
    let userID: String
    let timestamp: Int
    let comment: String
    let isNoUser: Bool
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case pollID
        case userID
        case timestamp, comment, isNoUser, displayName
    }
}

import SwiftUI
import SwiftyJSON

struct CommentsView: View {
    let api = NCAPIController()
    @State var message: String = ""
    @State var pollId: Int
    @State var comments = [Comment]()
//    @State var comments = Set<Comments>()
 
//    let arrayOfS = [Set<Int>]() // preferred
//    private var comments = []
//    var someSet = Set<Comment>()     //Character can be replaced by data type of set.

    func sendMessage() {
            print("Message: \(message)")
        self.message = ""
    }
    
    func getComments() {
        print("====================getComments============================")
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()
        
        api.getComments(account, forPollId: pollId as NSNumber) { response, error in
            let commentsArray : NSArray = response?["comments"] as? NSArray ?? []
     
              
            print("commentsArray..: \(String(describing: commentsArray))")
            
            var allComments = [Comment]()

            if response != nil {
 
                commentsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                    
                      let comment: Comment = try!  JSONDecoder().decode(Comment.self, from: jsonData)
                    
                    allComments.append(comment)
                 }
                                 
                comments = allComments;
                
                print(comments.count)

                
            }else{
                print("No results")
            }
            
            if(error != nil){
                print("Error: \(String(describing: error))")
            }
        }.resume()
    }
    
    var body: some View {
            
        VStack {
                    List {
         //               ForEach(chatHelper.realTimeMessages, id: \.self) { msg in
         //                  MessageView(checkedMessage: msg)
         //                }


                        HStack(alignment: .center, spacing: 10) {
                          Image("bunge")
                                    .resizable()
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .cornerRadius(20)

                            VStack{
                                HStack(alignment: .top, spacing: 10){
                                    Text("Steven Ogwal")
                                        .fontWeight(.bold)
                                    Text("~ a minute ago")
                                        .fontWeight(.ultraLight)
                                }
                                .font(.system(size: 16.0))
                                
                                Text("Internet inatupanga Internet inatupanga Internet inatupanga")
//                                    .padding(10)
//                                    .cornerRadius(10)
                            }.padding(8).frame(alignment: .leading)


                            Button(action: {
                                      print("button pressed")

                                    }) {
                                        Image("delete")
                                        .renderingMode(.original)
                                    }

                       }
                        
                        HStack(alignment: .center, spacing: 10) {
                          Image("bunge")
                                    .resizable()
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .cornerRadius(20)
                            
//                            LetterAvatarMaker()
//                                    .setCircle(true)
//                                    .setUsername("Letter Avatar")
//                                    .setBorderWidth(1.0)
//                                    .setBackgroundColors([ .red ])
//                                    .build()

                            VStack{
                                HStack(alignment: .top, spacing: 10){
                                    Text("Steven Ogwal")
                                        .fontWeight(.bold)
                                    Text("~ a minute ago")
                                        .fontWeight(.ultraLight)
                                }
                                .font(.system(size: 16.0))
                                
                                Text("Internet inatupanga Internet inatupanga Internet inatupanga")
//                                    .padding(10)
//                                    .cornerRadius(10)
                            }.padding(8).frame(alignment: .leading)


                            Button(action: {
                                      print("button pressed")

                                    }) {
                                        Image("delete")
                                        .renderingMode(.original)
                                    }

                       }
                        
                        HStack(alignment: .center, spacing: 10) {
                          Image("bunge")
                                    .resizable()
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .cornerRadius(20)

                            VStack{
                                HStack(alignment: .top, spacing: 10){
                                    Text("Steven Ogwal")
                                        .fontWeight(.bold)
                                    Text("~ a minute ago")
                                        .fontWeight(.ultraLight)
                                }
                                .font(.system(size: 16.0))
                                
                                Text("Internet inatupanga Internet inatupanga Internet inatupanga")
//                                    .padding(10)
//                                    .cornerRadius(10)
                            }.padding(8).frame(alignment: .leading)


                            Button(action: {
                                      print("button pressed")

                                    }) {
                                        Image("delete")
                                        .renderingMode(.original)
                                    }

                       }
                        
                        
                        
                        
                    }
            
                    // send message section
                    HStack {
                        TextField("Type a message", text: $message)
                        Button(action: self.sendMessage) {
                            Text("Send")
                        }
                    }.padding()
                }
                .navigationBarTitle("Comments")
                .onAppear {
                    print("Helloz")
                }
    }
}

struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}

