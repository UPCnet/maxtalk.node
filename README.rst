cMaxtalk NODE
============

Notification system for MAX conversations. The system is using socketIO as a base, on top of a node.js server, and implements the following protocol to communicate server and client:


Usage and protocol
------------------

The conceptual handshake steps are:

    * Client connects to socketIO
    * Client registers on *max* namespace
    * Client *joins* his current conversations

After that:

    * Client listens for events
    * Client sends messages


In a javascript client, this goes this way:

.. code-block:: javascript

        socket = io.connect('http://server/max')
        packet = {
            'username': 'user.name',
            'timestamp': 347815255145614
        }
        socket.join(packet)

Where ``username`` is the MAX user we want to listen for conversations and ``timestime`` is the *epoch* time of the ``join`` request. The server takes care of asking max for the conversations the user is registered, and it responds back to the ``join`` event emited by client with that information with a ``listening`` event witht the following format:

.. code-block:: javascript

         {
            'conversations': [
                'fasrgarbaa4wg4wgaw4',
                'fgq35q3958gh357fh35'
            ]
         }

where ``conversations`` is a list of conversations id's. At the same time user receives that information, server also notifies all the members of the registered conversations that a new user is listening on the conversation. This goes as a ``joined`` event that reads as:

.. code-block:: javascript

         {
            'conversation': 'fgq35q3958gh357fh35'
            'username': 'nom.cognom'
         }

where username is the new user that has joined the conversation. Obviously this event will be emmitted only to already listening users, and won't be received by the user that has just joined.

From that point, every message sent from client to server will be broadcasted to every user in the conversation except the sender. To send a message notification, the client has to emit a ``talk`` event with the following data:

.. code-block:: javascript

    {
        'conversation': 'fasrgarbaa4wg4wgaw4',
        'timestamp': 347815255145614,
        'messageID': 0f2343512345252
    }

where ``messageID`` is the id of the message we previously sent, and ``timestamp`` the time when the send message request was initated. Note that maxtalk doesn't actually send the messages, only notifies other users that a message has been sent. The actual message sending must be performed using the conversations max api.

The server will broadcast a ``update`` event to users in the conversation, telling them that a user sent a new message, so they have to update the message list. The ``messageID`` can be used to filter from which point we want to retrieve messages

.. code-block:: javascript

    {
        'username': 'nom.cognom',
        'conversation': 'fasrgarbaa4wg4wgaw4',
        'timestamp': 347815255145614,
        'messageID': 0f2343512345252
    }

The ``timestamp`` is the original timestamp when the message origined, so it can be used to measure delivery time.

For all of this to work, client must listen to the ``listening``, ``update`` and ``joined`` events, implementing the required actions for each as follows:

.. code-block:: javascript

    socket.on('eventname' function(data) {
        // Event's action implementation
    })
