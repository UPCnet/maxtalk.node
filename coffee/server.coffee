# Load dependencies
config = require('../../config/config.js')
max = require('./max')
http = require("http")

clustered = config.instances > 1
worker_pid = 0

# If clustered setup redis clients and spawn "workers"
if clustered
    RedisStore = require("socket.io/lib/stores/redis")
    redis = require("socket.io/node_modules/redis")
    pub = redis.createClient(config.redisport, config.redishost)
    sub = redis.createClient(config.redisport, config.redishost)
    client = redis.createClient(config.redisport, config.redishost)

    cluster = require("cluster")

    # Spawn only once
    if cluster.isMaster
      i = 0
      while i < config.instances
        cluster.fork()
        i++
      cluster.on 'fork', (worker) ->
        console.log 'forked worker ' + worker.process.pid
      cluster.on "listening", (worker, address) ->
        console.log "worker " + worker.process.pid + " is now connected to " + address.address + ":" + address.port

      cluster.on "exit", (worker, code, signal) ->
        console.log "worker " + worker.process.pid + " died"


# Setup http server and socketio endpoint
app = require("express")()
server = require("http").createServer(app)

socketio_settings =
    log: false

io = require("socket.io").listen(server, socketio_settings)
console.log "Socketio Started"

# Setup Redis Store on socketio only if we are in a cluster
if clustered
    io.set "store", new RedisStore(
        redisPub: pub
        redisSub: sub
        redisClient: client
    )

# Start http server
server.listen config.port
app.get "/", (req, res) ->
    res.sendfile(__dirname + '/index.html');

# Handle events inside a conversation
conversations = io.of(config.namespace).on "connection", (socket) ->
    console.log 'socket call handled by worker with pid ' + worker_pid

    # Handle users joining the service
    socket.on "join", (data) ->
        socket._max_username = data.username # store username in the socket

        # Find user conversations on Mongo
        max.User.find {username: data.username}, (err, doc) ->
            cids = (conversation.id for conversation in doc[0].talkingIn.items)

            # Notify user to which conversation is listening
            socket.emit "listening",
                conversations: cids

            # Push the user inside a room for each conversation
            # Rooms are created on demand, with the patern /max/xxxxxxxxxx
            # Where /max is the configured namespace name and xxxxx the conversation id
            socket.join cid for cid in cids

            # XXX DEBUG ONLY ??
            # Emits the number of people curently in a room to everyone in the room
            conversations.in(cid).emit 'people',
                inroom: conversations.manager.rooms[conversations.name+'/'+cid].length

            # Notify all conversation members (except sender)
            # that a user has joined a specific conversation
            socket.broadcast.to(cid).emit 'joined',
                username: data.username
                conversation: cid

    # Handle users sending messages
    socket.on "message", (data) ->
        # Notify all conversation members (except sender)
        # that a new message has been sent to the conversation
        socket.broadcast.to(data.conversation).emit 'update',
            username: socket._max_username
            timestamp: data.timestamp





