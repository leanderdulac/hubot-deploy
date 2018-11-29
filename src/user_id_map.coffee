Fs = require "fs"

userIdMap = JSON.parse Fs.readFileSync('user-id-map.json').toString()

userIdToName = (userId) -> userIdMap[userId]

exports.userIdToName = userIdToName
