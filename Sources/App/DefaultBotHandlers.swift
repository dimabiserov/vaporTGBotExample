//
//  File.swift
//  
//
//  Created by Дмитрий Бисеров on 17.06.2021.
//

import Vapor
import telegram_vapor_bot

struct T: Decodable {
    let text: String
 
}

final class DefaultBotHandlers {
    
    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        defaultHandler(app: app, bot: bot)
        commandPingHandler(app: app, bot: bot)
        commandCatHandler(app: app, bot: bot)
    }
    
    
    private static func commandCatHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/cat"]) { update, bot in
            app.http.client.shared.get(url: "https://cat-fact.herokuapp.com/facts").whenSuccess { result in
                guard let body = result.body, let data = body.getData(at: 0, length: body.readableBytes) else {
                    return
                }
                let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]],
                      let title = jsonArray.randomElement()?["text"] as? String else {
                      return
                }
                try? update.message?.reply(text: title, bot: bot)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    
    
    private static func defaultHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: (.all && !.command.names(["/ping"]))) { update, bot in
            // let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Success")
            // try bot.sendMessage(params: params)
            if let mediaID =  update.message?.photo?.last?.fileId {
                try? bot.getFile(params: TGGetFileParams(fileId: mediaID)).whenSuccess({ file in
                    guard let filePath = file.filePath else {
                        return
                    }
                    let url = "https://api.telegram.org/file/bot\(tgApi)/\(filePath)"
                    try? update.message?.reply(text: url, bot: bot)
                })
            }
            
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandPingHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/ping"]) { update, bot in
            try update.message?.reply(text: "pong", bot: bot)
        }
        bot.connection.dispatcher.add(handler)
    }
}
