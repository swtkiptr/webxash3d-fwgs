# Xash3D-FWGS Emscripten Web Port

This project is an [Emscripten](https://emscripten.org/)-based web port of [Xash3D-FWGS](https://github.com/FWGS/xash3d-fwgs), an open-source engine for games based on the GoldSource engine.

## Features

- **Web-based Counter-Strike 1.6 client** - Play CS 1.6 directly in your browser
- **WebSocket to UDP proxy** - Connect to traditional game servers from web clients
- **Full Emscripten compilation** - Native performance in the browser
- **Docker deployment** - Easy setup and deployment

# Compiling and running 

## Clone the repository

```bash
git clone --recurse-submodules https://github.com/yohimik/webxash3d-fwgs.git
cd webxash3d-fwgs
```

## Game Content

You must provide your own game files (e.g., from Steam):
```shell
steamcmd +force_install_dir ./hl +login your_steam_username +app_update 70 validate +quit
```

Zip and and copy the `valve` folder from your Half-Life installation into the `public/valve.zip`.
Note: zip contents should be like this:
```shell
/valve.zip
└── valve                  
  ├── file1           
  └── file2...  
```


## Compile and run

### hlsdk

```shell
docker compose -f hlsdk.docker-compose.yml up -d
```

Navigate in your browser to `http://localhost:8080`

<details>
  <summary>Screenshots (black frames - mac book camera, blue frames - browser active outline)</summary>

![hlsdk screenshot 0](./screenshots/hlsdk0.png)
![hlsdk screenshot 1](./screenshots/hlsdk1.png)
![hlsdk screenshot 2](./screenshots/hlsdk2.png)
![hlsdk screenshot 3](./screenshots/hlsdk3.png)
![hlsdk screenshot 4](./screenshots/hlsdk4.png)

</details>

### cs16-client

```shell
docker compose -f cs16-client.docker-compose.yml up -d
```

Navigate in your browser to `http://localhost:8081`

### Full Stack (CS Client + WebSocket Proxy)

For the complete setup including WebSocket proxy support for multiplayer:

```shell
docker compose -f full-stack.docker-compose.yml up -d
```

This will start:
- WebSocket to UDP proxy server on port 3000
- CS 1.6 web client on port 8080

Navigate to `http://localhost:8080` to play Counter-Strike 1.6 in your browser with full multiplayer support.

## WebSocket Proxy

The WebSocket proxy enables web-based CS clients to connect to traditional UDP game servers. See [WEBSOCKET_PROXY_README.md](./WEBSOCKET_PROXY_README.md) for detailed documentation.

### Quick Start

1. **Start the proxy server:**
   ```bash
   ./start-proxy.sh
   ```

2. **Or use Docker:**
   ```bash
   docker compose -f websocket-proxy.docker-compose.yml up -d
   ```

3. **Configure client** to point to your proxy server in `patches/head-cs.js`

<details>
  <summary>Screenshots (black frames - mac book camera, blue frames - browser active outline)</summary>

![cs16-client screenshot 0](./screenshots/cs16-client0.png)
![cs16-client screenshot 1](./screenshots/cs16-client1.png)
![cs16-client screenshot 2](./screenshots/cs16-client2.png)
![cs16-client screenshot 3](./screenshots/cs16-client3.png)

</details>

# TODO

## RAM optimization

Reduce current stack size to min.

## NPM

Fix all issues above and publish `xash3d-fwgs` npm package.

## WebGL improves (potentially)

Support GLES3Compat batching and fix `Vertex buffer is not big enough for the draw call.Understand this warning` warning.

## Scripts (potentially)

Some scripts stop working after saving and loading (eg. the guard doesn't open the train door).
