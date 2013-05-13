mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/max'

userSchema = mongoose.Schema
    username: String
    displayName: String
    talkingIn:
        items: [
          id: String
          objectType: String
        ]
        totalItems: Number

User = mongoose.model 'User', userSchema
exports.User = User

db = mongoose.connection
db.on 'error',  console.error.bind(console, 'connection error:')
db.once 'open', () ->
    console.log 'Mongo connected'



