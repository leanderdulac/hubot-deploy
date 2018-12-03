Fs = require "fs"

config = JSON.parse Fs.readFileSync('hubot-deploy-config.json').toString()

userIdToName = (userId) -> config.userIdMap[userId]

exports.userIdToName = userIdToName
