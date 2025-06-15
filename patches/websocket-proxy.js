// WebSocket Proxy Support for CS Client
// This script provides WebSocket to UDP proxy functionality

function skipRun() {
	savedRun = run;
	Module.run = haltRun;
	run = haltRun;

	Module.setStatus("Engine downloaded!");
	showElement('loader1', false);
	showElement('optionsTitle', true);

	if(window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB)
		showElement('idbHider', true);
	prepareSelects();
	showElement('fSettings',true);

	ENV.XASH3D_GAMEDIR = gamedir;
	ENV.XASH3D_RODIR = '/rodir'

	function loadModule(name) {
		var script = document.createElement('script');
		script.onload = function(){moduleCount++;if(moduleCount==3){Module.setStatus("Scripts downloaded!");}};
		document.body.appendChild(script);
		script.src = name + ".js";
	}

	loadModule("server");
	loadModule("client");
	loadModule("menu");
}

// Initialize WebSocket proxy configuration
Module.preInit = Module.preInit || [];
Module.preInit.push(skipRun);

Module.websocket = Module.websocket || {};
Module.websocket.url = 'wsproxy://the-swank.pp.ua:3000/';

// Environment variables
ENV = ENV || [];

// WebSocket proxy connection manager
Module.websocketConnections = new Map();

// Enhanced WebSocket proxy implementation
Module.websocketProxyConnect = function(host, port, protocol) {
	protocol = protocol || 'udp';
	const connectionId = host + ':' + port;
	
	// Check if connection already exists
	if (Module.websocketConnections.has(connectionId)) {
		const existing = Module.websocketConnections.get(connectionId);
		if (existing.socket.readyState === WebSocket.OPEN) {
			return existing;
		} else {
			Module.websocketConnections.delete(connectionId);
		}
	}
	
	const wsUrl = Module.websocket.url.replace('wsproxy://', 'ws://') + 
		'?host=' + encodeURIComponent(host) + 
		'&port=' + encodeURIComponent(port) + 
		'&protocol=' + encodeURIComponent(protocol);
	
	console.log('Connecting to WebSocket proxy:', wsUrl);
	const ws = new WebSocket(wsUrl);
	ws.binaryType = 'arraybuffer';
	
	const connection = {
		socket: ws,
		host: host,
		port: port,
		protocol: protocol,
		connected: false,
		
		send: function(data) {
			if (ws.readyState === WebSocket.OPEN) {
				try {
					ws.send(data);
					return true;
				} catch (e) {
					console.error('WebSocket send error:', e);
					return false;
				}
			}
			return false;
		},
		
		close: function() {
			try {
				ws.close();
			} catch (e) {
				console.error('WebSocket close error:', e);
			}
			Module.websocketConnections.delete(connectionId);
		},
		
		onopen: null,
		onmessage: null,
		onclose: null,
		onerror: null
	};
	
	ws.onopen = function(event) {
		console.log('WebSocket proxy connected to', host + ':' + port);
		connection.connected = true;
		if (connection.onopen) connection.onopen(event);
	};
	
	ws.onmessage = function(event) {
		if (connection.onmessage) connection.onmessage(event);
	};
	
	ws.onclose = function(event) {
		console.log('WebSocket proxy disconnected from', host + ':' + port);
		connection.connected = false;
		Module.websocketConnections.delete(connectionId);
		if (connection.onclose) connection.onclose(event);
	};
	
	ws.onerror = function(event) {
		console.error('WebSocket proxy error for', host + ':' + port, event);
		if (connection.onerror) connection.onerror(event);
	};
	
	Module.websocketConnections.set(connectionId, connection);
	return connection;
};

// Helper function to get all active connections
Module.getActiveConnections = function() {
	return Array.from(Module.websocketConnections.values()).filter(conn => conn.connected);
};

// Cleanup function
Module.cleanupWebSocketConnections = function() {
	Module.websocketConnections.forEach((connection, id) => {
		if (connection.socket.readyState !== WebSocket.OPEN) {
			Module.websocketConnections.delete(id);
		}
	});
};

// Auto-cleanup every 30 seconds
setInterval(Module.cleanupWebSocketConnections, 30000);

console.log('WebSocket proxy support initialized');