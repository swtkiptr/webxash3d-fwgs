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

// WebSocket proxy configuration
Module.websocket = Module.websocket || {};
Module.websocket.url = 'wsproxy://the-swank.pp.ua:3000/';

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
		}
	};
};
