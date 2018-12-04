Fs = require "fs"

config = JSON.parse Fs.readFileSync('hubot-deploy-config.json').toString()

changelogRepository = config.changelogRepository
userIdToName = (userId) -> config.userIdMap[userId]

module.exports = {
  changelogRepository,
  userIdToName,
}
