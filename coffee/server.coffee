#cluster = require("cluster")
http = require("http")
numCPUs = require("os").cpus().length
RedisStore = require("socket.io/lib/stores/redis")
redis = require("socket.io/node_modules/redis")
pub = redis.createClient()
sub = redis.createClient()
client = redis.createClient()
# if cluster.isMaster
#   i = 0
#   #while i < numCPUs
#   while i < 1
#     cluster.fork()
#     i++
#   cluster.on 'fork', (worker) ->
#     console.log 'forked worker ' + worker.process.pid
#   cluster.on "listening", (worker, address) ->
#     console.log "worker " + worker.process.pid + " is now connected to " + address.address + ":" + address.port
#   cluster.on "exit", (worker, code, signal) ->
#     console.log "worker " + worker.process.pid + " died"
# else
max = require('./max')
app = require("express")()
server = require("http").createServer(app)
io = require("socket.io").listen(server)
io.set "store", new RedisStore(
  redisPub: pub
  redisSub: sub
  redisClient: client
)
server.listen 6777
app.get "/", (req, res) ->
  res.sendfile(__dirname + '/index.html');


io.sockets.on "connection", (socket) ->
  console.log 'socket call handled by worker with pid ' + process.pid

conversations = io.of("/max").on "connection", (socket) ->
  console.log 'socket call handled by worker with pid ' + process.pid

  socket.on "join", (data) ->
    socket._max_username = data.username
    max.User.find {username: data.username}, (err, doc) ->
      cids = (conversation.id for conversation in doc[0].talkingIn.items)
      socket.emit "listening",
        conversations: cids

      socket.join cid for cid in cids

      conversations.in(cid).emit 'people',
        inroom: conversations.manager.rooms[conversations.name+'/'+cid].length

      socket.broadcast.to(cid).emit 'joined',
        username: data.username
        conversation: cid

  socket.on "message", (data) ->
    socket.broadcast.to(data.conversation).emit 'update',
      username: socket._max_username
      timestamp: data.timestamp





