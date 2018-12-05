Path = require "path"
config = require(Path.join(__dirname, "config"))

getCommitTitle = (commit) ->
    commit.message.split('\n\n')[0]

defaultBranch = (api, repository) ->
  ghrepo = api.repo(repository)
  new Promise (resolve, reject) ->
    ghrepo.info (err, data) ->
      if err
        return reject err

      resolve data.default_branch

branchComparison = (api, repository, baseBranch, ref) ->
  ghrepo = api.repo(repository)
  new Promise (resolve, reject) ->
    ghrepo.compare baseBranch, ref, (err, data) ->
      if err
        return reject err

      resolve data.commits.map (commit) ->
        url: commit.html_url
        title: getCommitTitle(commit.commit)

post = (api, repository, baseBranch, ref, destination, changes, userid) ->
  ghrepo = api.repo(config.changelogRepository)
  timestamp = (new Date).toISOString().slice(0, -5)
  username = config.userIdToName(userid)
  body = changes
    .map (change) ->
      "* [#{change.title}](#{change.url})"
    .join '\n'

  new Promise (resolve, reject) ->
    ghrepo.createIssue({
      title: "#{repository} - #{destination} - #{timestamp}",
      body: """
        ### Deploy infos

        **Author:** #{username} (#{userid})
        **From branch:** #{ref}
        **Base branch:** #{baseBranch}
        **Destination:** #{destination}
        **Timestamp:** #{timestamp}

        ### Changelog

        #{body}
      """,
    }, (err, data) ->
      if err
        return reject err

      resolve(data.html_url)
    )

create = (api, repository, ref, destination, userid) ->
  baseBranch = null

  defaultBranch(api, repository)
    .then (defaultBranch) ->
      baseBranch = defaultBranch

      branchComparison(
        api,
        repository,
        baseBranch,
        ref,
      )
    .then (changes) ->
      post(
        api,
        repository,
        baseBranch,
        ref,
        destination,
        changes,
        userid,
      )

module.exports = {
    create,
}
