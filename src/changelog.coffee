Path = require "path"
config = require(Path.join(__dirname, "config"))

getCommitTitle = (commit) ->
    commit.message.split('\n\n')[0]

branchComparison = (api, repository, ref) ->
  ghrepo = api.repo(repository)
  new Promise (resolve, reject) ->
    ghrepo.compare 'master', ref, (err, data) ->
      if err
        return reject err

      resolve data.commits.map (commit) ->
        url: commit.html_url
        title: getCommitTitle(commit.commit)

post = (api, ref, changes, userid) ->
  ghrepo = api.repo(config.changelogRepository)
  username = config.userIdToName(userid)
  body = changes
    .map (change) ->
      "* [#{change.title}](#{change.url})"
    .join '\n'

  new Promise (resolve, reject) ->
    ghrepo.createIssue({
      title: 'Changelog',
      body: """
        ### Deploy infos

        **Author:** #{username} (#{userid})
        **From branch:** #{ref}
        **Base branch:** master

        ### Changelog

        #{body}
      """,
    }, (err, data) ->
      if err
        return reject err

      resolve(data.html_url)
    )

create = (api, repository, ref, userid) ->
  branchComparison(
    api,
    repository,
    ref,
  )
  .then (changes) ->
    post(
      api,
      ref,
      changes,
      userid,
    )

module.exports = {
    create,
}
