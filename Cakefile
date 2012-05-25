{exec, execFile, spawn} = require 'child_process'
fs = require 'fs'
{series} = require 'async'
CoffeeScript = require "coffee-script"

sh = (command) -> (k) ->
  console.log "Executing #{command}"
  exec command, (err, sout, serr) ->
    console.log err if err
    console.log sout if sout
    console.log serr if serr
    do k

buildDir = (path) ->
  console.log "Compiling CoffeeScript from 'src/#{path}' to '#{path}"
  exec "coffee -c -o #{__dirname}/#{path} #{__dirname}/src/#{path}", (err, stdout, stderr) ->
    console.log stderr if stderr

printLine = (line) -> process.stdout.write line + '\n'

lint = (file) ->
  fs.readFile file, (err, data) ->
    return console.error err if err?
    cs = data.toString()
    js = CoffeeScript.compile cs
    printIt = (buffer) ->
      output = buffer.toString().trim()
      return if output == "0 error(s), 0 warning(s)"
      printLine "\n#{file}:\n#{output}"
    conf = __dirname + '/jsl.conf'
    jsl = spawn 'jsl', ['-nologo', '-stdin', '-conf', conf]
    jsl.stdout.on 'data', printIt
    jsl.stderr.on 'data', printIt
    jsl.stdin.write js
    jsl.stdin.end()

sourcefiles = (callback) ->
  execFile "find", ['src', '-name', '*.coffee'], (err, sout, serr) ->
    return console.error err if err?
    callback (sout.split "\n").slice 0, -1

task 'build', 'transpile CoffeeScript sources to JavaScript', ->
  buildDir "lib"
  buildDir "components"
  buildDir "bin"

task 'test', 'run the unit tests', ->
  sh('npm test') ->

task "lint", "Lint CoffeeScript files", ->
  sourcefiles (files) ->
    lint file for file in files

task 'doc', 'generate documentation for *.coffee files', ->
  sh('./node_modules/docco-husky/bin/generate src') ->

task 'docpub', 'publish documentation into GitHub pages', ->
  series [
    (sh "./node_modules/docco-husky/bin/generate src")
    (sh "mv docs docs_tmp")
    (sh "git checkout gh-pages")
    (sh "cp -R docs_tmp/* docs/")
    (sh "git add docs/*")
    (sh "git commit -m 'Documentation update'")
    (sh "git checkout master")
  ]
