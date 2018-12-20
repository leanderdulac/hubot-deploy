Path = require("path")
{
  PullRequest,
  states,
  isValidPullRequestList,
  isValidPullRequest
} = require(Path.join(__dirname, "../src", "pull_request"))

repoInfo = require(Path.join(__dirname, "fixtures", "repo-info.json"))
allBranches = require(Path.join(__dirname, "fixtures", "all-branches.json"))
pullRequestList = require(Path.join(__dirname, "fixtures", "pull-request-list.json"))
pullRequest = require(Path.join(__dirname, "fixtures", "pull-request.json"))

response = (path, callback, branch) ->
  if path.endsWith('pulls')
    list = pullRequestList.filter (b) -> b.head.ref == branch
    return callback null, 200, list

  if path.indexOf('pulls') >= 0
    pull = pullRequest.filter (b) -> b.head.ref == branch
    return callback null, 200, pull[0]

  if path.indexOf('branches') >= 0
    return callback null, 200, allBranches

  return callback null, 200, repoInfo

getPullRequestState = (request, branch) ->
  config =
    path: (url) -> url

  pr = new PullRequest(branch, 'batatao', request, config)

  return pr.getPullRequestState()

describe "Branch Pull Request", () ->
  describe "Unit Tests", () ->
    it "should return error if the branch has no pull request", () ->
      assert.equal(isValidPullRequestList([]), states.NoPullRequests)

    it "should return error if the branch has more than one pull request", () ->
      twoPullrequests = pullRequestList.filter (b) -> b.head.ref == 'two-pr'
      assert.equal(isValidPullRequestList(twoPullrequests), states.TooManyPullRequests)

    it "should return success if the branch has only one pull request", () ->
      onePullrequest = pullRequestList.filter (b) -> b.head.ref == 'one-pr'
      assert.equal(isValidPullRequestList(onePullrequest), states.Ok)

    it "should return error if the pull request is not mergeable", () ->
      blockedPullRequest = pullRequest.filter((b) -> b.head.ref == 'blocked')[0]
      assert.equal(isValidPullRequest(blockedPullRequest), states.BlockedPullRequest)

    it "should return success if the pull request is mergeable", () ->
      cleanPullRequest = pullRequest.filter((b) -> b.head.ref == 'clean')[0]
      assert.equal(isValidPullRequest(cleanPullRequest), states.Ok)

  describe "Integration Tests", () ->
    it "should return error if the branch has no pull request", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'no-pr'

      getPullRequestState(request, 'no-pr')
        .then (state) ->
          assert.equal(state, states.NoPullRequests)

    it "should return error if the branch has more than one pull request", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'two-pr'

      getPullRequestState(request, 'two-pr')
        .then (state) ->
          assert.equal(state, states.TooManyPullRequests)

    it "should return success if the branch has only one pull request", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'one-pr'

      getPullRequestState(request, 'one-pr')
        .then (state) ->
          assert.equal(state, states.Ok)

    it "should return error if the pull request is not mergeable", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'blocked'

      getPullRequestState(request, 'blocked')
        .then (state) ->
          assert.equal(state, states.BlockedPullRequest)

    it "should return success if the pull request is mergeable", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'clean'

      getPullRequestState(request, 'clean')
        .then (state) ->
          assert.equal(state, states.Ok)

    it "should return success if it is the main branch", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'main-branch'

      getPullRequestState(request, 'main-branch')
        .then (state) ->
          assert.equal(state, states.Ok)

    it "should return success if it is not branch", () ->
      request = get: (path, params, callback) ->
        response path, callback, 'i-am-a-commit'

      getPullRequestState(request, 'i-am-a-commit')
        .then (state) ->
          assert.equal(state, states.Ok)
