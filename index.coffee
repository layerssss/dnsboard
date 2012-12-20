
###
Module dependencies.
###
express = require("express")
http = require("http")
path = require("path")
api = require 'mikronode'

MemoryStore = express.session.MemoryStore;
app = express()

app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "ros_addr", process.env.ROS_ADDR or throw new Error 'ROS_ADDR NOT SET'
  app.set "ros_user", process.env.ROS_USER or throw new Error 'ROS_USER NOT SET'
  app.set "ros_pass", process.env.ROS_PASS or throw new Error 'ROS_PASS NOT SET'
  app.set "views", __dirname
  app.set "view engine", "jade"
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session
    secret: "nodlog"
    store: new MemoryStore
      reapInterval:  60000 * 10
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()
connection = null
new api(app.get("ros_addr"),app.get('ros_user'),app.get('ros_pass')).connect (conn)->
  connection = conn

app.all "/",(req,res,next)->
    res.locals.chan = connection.openChannel()
    next()

app.post "/",(req,res,next)->
  res.locals.ip = req.headers['x-forwarded-for']||req.connection.remoteAddress
  chan = res.locals.chan
  chan.write '/ip/dns/static/print',->
    chan.on 'done',(data)->
      for dns in api.parseItems data
        if dns.address==res.locals.ip
          chan.write ['/ip/dns/static/remove',"=.id=#{dns['.id']}"],->
            chan.on 'done',(data)->
              next()
          return
      next()
app.post "/",(req,res,next)->
  chan = res.locals.chan
  chan.write ['/ip/dns/static/add',"=name=#{req.body.name}","=address=#{res.locals.ip}",'=ttl=60'],->
    chan.on 'done',()->
      next()

app.all "/",(req,res,next)->
  chan = res.locals.chan
  chan.write '/ip/dns/static/print',->
    chan.on 'done',(data)->
      res.locals.dns = api.parseItems data
      chan.write '/ip/dhcp-server/lease/print',->
        chan.on 'done',(data)->
          res.locals.dhcp = api.parseItems data
          res.locals.chan.close()
          res.render 'index',
            name: req.body.name




http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
