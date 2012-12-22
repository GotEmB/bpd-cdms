express = require "express"
http = require "http"
socket_io = require "socket.io"
md5 = require "MD5"
{spawn} = require "child_process"
core = require "./core"
db = require "./db"

cp = spawn "cake", ["build"]
await cp.on "exit", defer code
return console.log "Build failed! Run 'cake build' to display build errors." if code isnt 0

expressServer = express()
expressServer.configure ->

	expressServer.use express.bodyParser()
	expressServer.use (req, res, next) ->
		req.url = "/page.html" if req.url is "/"
		next()
	expressServer.use express.static "#{__dirname}/lib", maxAge: 31557600000, (err) -> console.log "Static: #{err}"
	expressServer.use expressServer.router

server = http.createServer expressServer

io = socket_io.listen server
io.set "log level", 0
io.sockets.on "connection", (socket) ->

	socket.on "getCourses", (callback) ->
		console.log "Fetching Courses"
		db.Course.find({}).lean().exec (err, courses) ->
			callback courses

	socket.on "commitCourses", (courses, callback) ->
		console.log "Committing Courses"
		core.commitCourses courses, callback

	socket.on "uploadCourses", (file, callback) ->
		console.log "New Upload Courses"
		core.buildCoursesCollection file, callback

	socket.on "uploadStudents", (file, callback) ->
		console.log "New Upload Students"
		core.buildStudentsCollection file, callback

server.listen (port = process.env.PORT ? 5000), -> console.log "Listening on port #{port}"