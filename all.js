var GeoLocation = function (geochat, callback) {
    this.setupGeolocation(_.bind(callback, geochat));
};
GeoLocation.prototype = {
    setupGeolocation: function (callback) {
        if (!navigator.geolocation) {
            new Error('No geolocation!');
        };

        navigator.geolocation.getCurrentPosition(callback, this.geolocationError);
    },

    geolocationError: function (error) {
    }
};

var GeoChat = function () {
    this.startSocket();
};
GeoChat.prototype = {
    startSocket: function () {
        this.socket = new WebSocket('ws://localhost:5000');

        var onOpen = _.bind(this.onOpen, this);
        var onMessage = _.bind(this.onMessage, this);

        this.socket.onopen = onOpen;
        this.socket.onmessage = onMessage;
    },

    sendLocation: function (position) {
        this.send([position.coords.latitude, position.coords.longitude]);
    },

    send: function (message) {
        if (typeof this.socket === 'object') {
            console.log("Sending message: " + message);
            this.socket.send(message);
        } else {
            console.log('Trying to send message, but not connected: ' + message);
        };
    },

    onOpen: function (event) {
        console.log("Connected!");
        this.locationService = new GeoLocation(this, this.sendLocation);
    },

    onMessage: function (message) {
        console.log(message.data);
    }
};

var chat = new GeoChat();
