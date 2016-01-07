Async = require "async"
Fs = require "fs"
Git = require "nodegit"
Promisify = require "node-promisify"
Rimraf = require "rimraf"

Clone = Git.Clone
Rimraf = Promisify Rimraf

internals = {}

exports.update = (cfg, cb) ->
  Async.auto
    blog: (next) ->
      options =
        encoding: "utf-8"

      Fs.readFile cfg.srcPath, options, next

    logs: (next) ->
      internals.getLogs cfg.repoUrl, next

    updatedBlog: ["blog", "logs", (next, results) ->
      updatedBlog = internals.updateBlog
        repoUrl: cfg.repoUrl
        blog: results.blog
        logs: results.logs

      Fs.writeFile cfg.dstPath, updatedBlog
    ]

  , cb

internals.getLogs = (repoUrl, cb) ->
  repoPath = "/tmp/blogRepo"

  Rimraf repoPath
    .then ->
      Clone.clone repoUrl, repoPath

    .then (repo) ->
      repo.getMasterCommit()

    .then (head) ->
      logs = []
      history = head.history()

      history.on "commit", (commit) ->
        logs.push
          sha: commit.sha()
          message: commit.message()

      history.on "end", ->
        cb null, logs

      history.on "error", (err) ->
        cb err

      history.start();

    .catch cb

internals.updateBlog = ({ repoUrl, blog, logs }) ->
  logs.reduce (updatedBlog, { sha, message }) ->
    [..., step] = message.match /^Step (.*)\: .*\n$/

    updatedBlog.replace(
      new RegExp("<div(.*)><strong>#{step}</strong>&nbsp; (.*) <a(.*) href=\"#{repoUrl}/commit/.*\"> (.*) </a></div>", "g"),
      "<div$1><strong>#{step}</strong>&nbsp; $2 <a$3 href=\"#{repoUrl}/commit/#{sha}\"> $4 </a></div>"
    )

  , blog