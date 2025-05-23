# Xash3D-FWGS Emscripten Web Port

This project is an [Emscripten](https://emscripten.org/)-based web port of [Xash3D-FWGS](https://github.com/FWGS/xash3d-fwgs), an open-source engine for games based on the GoldSource engine.

# Compiling and running 

## Clone the repository

```bash
git clone --recurse-submodules https://github.com/yohimik/webxash3d-fwgs.git
cd webxash3d-fwgs
```

## Game Content

You must provide your own game files (e.g., from Steam):
```shell
steamcmd +login your_steam_username +force_install_dir ./hl +app_update 70 validate +quit
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

```shell
docker compose up -d
```

Navigate in your browser to `http://localhost:8080`

# TODO

## Mouse Crashes

The game crashes when capturing the mouse input (without `-noenginemouse`).

## RAM optimization

Reduce current stack size to min.
