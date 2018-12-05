Fs = require "fs"

applications = JSON.parse Fs.readFileSync("apps.json").toString()

config = JSON.parse Fs.readFileSync('hubot-deploy-config.json').toString()

changelogRepository = config.changelogRepository
userIdToName = (userId) -> config.userIdMap[userId]

module.exports = {
  applications,
  changelogRepository,
  userIdToName,
}
