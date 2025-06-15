import * as fflate from 'https://cdn.skypack.dev/fflate@0.8.2?min';
var Module = typeof Module != 'undefined' ? Module : {};
Module.dynamicLibraries = [
	"filesystem_stdio",
	"ref_gles3compat.so",
	"ref_soft.so",
	"menu",
	"server.wasm",
	"client.wasm",
]
Module.arguments = ['-game', 'cstrike', '+_vgui_menus', '0']
Module['canvas'] = document.getElementById('canvas')
Module.ctx = document.getElementById('canvas').getContext('webgl2', {alpha:false, depth: true, stencil: true, antialias: true})

// WebSocket proxy configuration for all-in-one container
Module.websocket = Module.websocket || {};

// Use local websockify-c proxy (running in same container)
Module.websocket.url = 'wsproxy://localhost:3000/';

// WebSocket proxy implementation
Module.websocketProxyConnect = function(host, port) {
	const wsUrl = Module.websocket.url.replace('wsproxy://', 'ws://') + '?host=' + host + '&port=' + port;
	const ws = new WebSocket(wsUrl);
	
	ws.binaryType = 'arraybuffer';
	
	return {
		socket: ws,
		send: function(data) {
			if (ws.readyState === WebSocket.OPEN) {
				ws.send(data);
			}
		},
		close: function() {
			ws.close();
		},
		onopen: null,
		onmessage: null,
		onclose: null,
		onerror: null
	};
};

// Override the default WebSocket connection for game networking
if (typeof Module.websocket !== 'undefined') {
	console.log('WebSocket proxy enabled:', Module.websocket.url);
}

Module.preRun = Module.preRun || [];
Module.preRun.push(function() {
	console.log('WebXash3D All-in-One: CS Client + websockify-c proxy ready');
	console.log('WebSocket proxy URL:', Module.websocket.url);
});

Module.print = function(text) {
	if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
	console.log(text);
};

Module.printErr = function(text) {
	if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
	console.error(text);
};

Module.setStatus = function(text) {
	if (!Module.setStatus.last) Module.setStatus.last = { time: Date.now(), text: '' };
	if (text === Module.setStatus.last.text) return;
	var m = text.match(/([^(]+)\((\d+(\.\d+)?)\/(\d+)\)/);
	var now = Date.now();
	if (m && now - Module.setStatus.last.time < 30) return; // if this is a progress update, skip it if too soon
	Module.setStatus.last.time = now;
	Module.setStatus.last.text = text;
	if (text) {
		console.log('Status:', text);
	}
};

Module.totalDependencies = 0;
Module.monitorRunDependencies = function(left) {
	this.totalDependencies = Math.max(this.totalDependencies, left);
	Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
};