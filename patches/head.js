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
Module.arguments = []
Module['canvas'] = document.getElementById('canvas')
Module.ctx = document.getElementById('canvas').getContext('webgl2', {alpha:false, depth: true, stencil: true, antialias: true})
