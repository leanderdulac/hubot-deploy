states =
  Ok: 0
  NoPullRequests: 1
  TooManyPullRequests: 2
  BlockedPullRequest: 3

isValidPullRequestList = (pulls) ->
  if pulls.length > 1
    return states.TooManyPullRequests

  if pulls.length < 1
    return states.NoPullRequests

  return states.Ok

isValidPullRequest = (pullrequest) ->
  if pullrequest.mergeable_state == 'blocked'
    return states.BlockedPullRequest

  return states.Ok

class PullRequest
  constructor: (@application, @branch, @repository, @request, @config) ->

  checkPullRequestMergeableState: (prNumber, resolve, reject) ->
    path = @config.path("repos/#{@repository}/pulls/#{prNumber}")

    @request.get path, {}, (err, status, body) ->
      if err
        return reject err

      return resolve isValidPullRequest body

  checkOpenPullRequests: (resolve, reject) ->
    path = @config.path("repos/#{@repository}/pulls")
    organization = @repository.split('/').shift()

    params =
      state: "open"
      head: "#{organization}:#{@branch}"

    @request.get path, params, (err, status, pulls) =>
      if err
        return reject err

      isValidList = isValidPullRequestList pulls

      if isValidList != states.Ok
        return resolve isValidList

      return @checkPullRequestMergeableState pulls[0].number, resolve, reject

  usingCommit: (resolve, reject) ->
    path = @config.path("repos/#{@repository}/branches")

    @request.get path, {}, (err, status, body) =>
      if err
        return reject err

      sameBranch = (branch) =>
        branch.name == @branch

      findBranch = body.find(sameBranch)

      if !findBranch
        return resolve states.Ok

      @checkOpenPullRequests resolve, reject

  usingMainBranch: (resolve, reject) ->
    path = @config.path("repos/#{@repository}")

    @request.get path, {}, (err, status, body) =>
      if err
        return reject err

      if body.default_branch == @branch
        return resolve states.Ok

      @usingCommit resolve, reject

  getPullRequestState: () =>
    new Promise (resolve, reject) =>
      if !@application.code_owner_review
        return resolve states.Ok

      return @usingMainBranch resolve, reject

module.exports = {
  isValidPullRequestList,
  isValidPullRequest,
  PullRequest,
  states
}
